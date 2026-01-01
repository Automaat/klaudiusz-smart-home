{
  lib,
  pkgs,
  nixosConfig,
}: let
  testLib = import ./lib.nix {inherit lib;};
  haConfig = nixosConfig.services.home-assistant.config;

  # ===========================================
  # Collect Defined Entities
  # ===========================================
  # Collect all entities defined in the config
  definedEntities = let
    # Input helpers
    inputBooleans = lib.mapAttrsToList (name: _: "input_boolean.${name}") (haConfig.input_boolean or {});
    inputNumbers = lib.mapAttrsToList (name: _: "input_number.${name}") (haConfig.input_number or {});
    inputSelects = lib.mapAttrsToList (name: _: "input_select.${name}") (haConfig.input_select or {});
    inputTexts = lib.mapAttrsToList (name: _: "input_text.${name}") (haConfig.input_text or {});
    inputDatetimes = lib.mapAttrsToList (name: _: "input_datetime.${name}") (haConfig.input_datetime or {});

    # Scripts
    scripts = lib.mapAttrsToList (name: _: "script.${name}") (haConfig.script or {});

    # Automations (as entities)
    automations = builtins.map (auto: "automation.${auto.id}") (haConfig.automation or []);

    # Template sensors (if any)
    templateSensors =
      if haConfig ? template
      then
        lib.flatten (builtins.map (t:
          if t ? sensor
          then
            builtins.map (s: "sensor.${s.unique_id}")
            (lib.filter (s: s ? unique_id) t.sensor)
          else [])
        haConfig.template)
      else [];
  in
    lib.flatten [
      inputBooleans
      inputNumbers
      inputSelects
      inputTexts
      inputDatetimes
      scripts
      automations
      templateSensors
    ];

  # ===========================================
  # Collect Referenced Entities
  # ===========================================
  # Collect all entity_id references from intents and automations
  collectEntityReferences = config: let
    extractEntityIds = entityId:
      if builtins.isString entityId
      then [entityId]
      else if builtins.isList entityId
      then entityId
      else [];

    # From intent_script actions
    intentEntities = lib.flatten (
      lib.mapAttrsToList (name: intent:
        if intent ? action
        then
          lib.flatten (builtins.map (action:
            if action ? target && action.target ? entity_id
            then extractEntityIds action.target.entity_id
            else [])
          intent.action)
        else [])
      (config.intent_script or {})
    );

    # From automation triggers
    automationTriggerEntities = lib.flatten (
      builtins.map (auto:
        if auto ? trigger
        then
          lib.flatten (builtins.map (trigger:
            if trigger ? entity_id
            then extractEntityIds trigger.entity_id
            else [])
          auto.trigger)
        else [])
      config.automation
    );

    # From automation conditions
    automationConditionEntities = lib.flatten (
      builtins.map (auto:
        if auto ? condition
        then
          lib.flatten (builtins.map (cond:
            if cond ? entity_id
            then extractEntityIds cond.entity_id
            else [])
          auto.condition)
        else [])
      config.automation
    );

    # From automation actions
    automationActionEntities = lib.flatten (
      builtins.map (auto:
        if auto ? action
        then
          lib.flatten (builtins.map (action:
            if action ? target && action.target ? entity_id
            then extractEntityIds action.target.entity_id
            else if action ? entity_id
            then extractEntityIds action.entity_id
            else [])
          auto.action)
        else [])
      config.automation
    );
  in
    intentEntities
    ++ automationTriggerEntities
    ++ automationConditionEntities
    ++ automationActionEntities;

  referencedEntities = collectEntityReferences haConfig;

  # ===========================================
  # Validation
  # ===========================================
  # Filter to only static entity IDs (no templates, no "all")
  staticReferences = lib.filter (e:
    e
    != "all"
    && !(lib.hasInfix "{{" e)
    && !(lib.hasInfix "{%" e)
    && testLib.isValidEntityId e)
  referencedEntities;

  # Find dangling references (referenced but not defined)
  # Note: Only checks Nix-defined entities, not runtime entities from integrations
  danglingReferences = lib.filter (e: !(builtins.elem e definedEntities)) staticReferences;

  # Unique dangling references
  uniqueDanglingReferences = lib.unique danglingReferences;

  # ===========================================
  # Test Results
  # ===========================================
  entityReferencesValid =
    if uniqueDanglingReferences != []
    then
      pkgs.runCommand "entity-references-check" {} ''
        echo "WARN: Entity references found that are not defined in Nix config:"
        echo "These may be runtime entities from integrations (normal) or typos (error)."
        echo ""
        ${lib.concatStringsSep "\n" (builtins.map (e: "printf '  - %s\\n' ${lib.escapeShellArg e}") uniqueDanglingReferences)}
        echo ""
        echo "Defined entities (${toString (builtins.length definedEntities)}):"
        ${lib.concatStringsSep "\n" (builtins.map (e: "printf '  - %s\\n' ${lib.escapeShellArg e}") definedEntities)}
        echo ""
        echo "PASS: Entity reference validation complete (warnings only)"
        touch $out
      ''
    else
      pkgs.runCommand "entity-references-check" {} ''
        echo "PASS: All static entity references are valid (${toString (builtins.length staticReferences)} checked)"
        echo "Defined entities: ${toString (builtins.length definedEntities)}"
        touch $out
      '';
in {
  inherit definedEntities referencedEntities staticReferences uniqueDanglingReferences;

  # Export for use in flake checks
  all = entityReferencesValid;
}
