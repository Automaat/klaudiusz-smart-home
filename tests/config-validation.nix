{
  lib,
  pkgs,
  nixosConfig,
}: let
  testLib = import ./lib.nix {inherit lib;};
  haConfig = nixosConfig.services.home-assistant.config;

  # Extract Nix intent names
  nixIntents = testLib.extractIntentNames haConfig.intent_script;

  # Extract automation IDs
  automationIds = testLib.extractAutomationIds haConfig.automation;

  # Collect all service calls from intents and automations
  collectServiceCalls = config: let
    intentServices = lib.flatten (
      lib.mapAttrsToList (_: intent:
        if intent ? action
        then lib.flatten (builtins.map (a: a.service or null) intent.action)
        else [])
      config.intent_script
    );
    automationServices = lib.flatten (
      builtins.map (auto:
        lib.flatten (builtins.map (a: a.service or null) auto.action))
      config.automation
    );
  in
    lib.filter (s: s != null) (intentServices ++ automationServices);

  # Collect all entity_id targets from intents and automations
  collectEntityIds = config: let
    extractEntityIds = entityId:
      if builtins.isString entityId
      then [entityId]
      else if builtins.isList entityId
      then entityId
      else [];

    intentEntities = lib.flatten (
      lib.mapAttrsToList (_: intent:
        if intent ? action
        then
          lib.flatten (builtins.map (a:
            if a ? target && a.target ? entity_id
            then extractEntityIds a.target.entity_id
            else [])
          intent.action)
        else [])
      config.intent_script
    );
    automationEntities = lib.flatten (
      builtins.map (auto:
        lib.flatten (builtins.map (a:
          if a ? target && a.target ? entity_id
          then extractEntityIds a.target.entity_id
          else [])
        auto.action))
      config.automation
    );
  in
    lib.filter (e: e != "all") (intentEntities ++ automationEntities);

  serviceCalls = collectServiceCalls haConfig;
  entityIds = collectEntityIds haConfig;

  # =============================================
  # Test Results
  # =============================================

  # Test 1: Automation IDs are unique
  duplicateIds = testLib.findDuplicates automationIds;
  automationIdsUnique =
    if duplicateIds != []
    then
      throw ''
        FAIL: Duplicate automation IDs found:
        ${lib.concatStringsSep "\n" (builtins.map (id: "  - ${id}") duplicateIds)}
      ''
    else "PASS: All automation IDs are unique";

  # Test 2: Service calls are valid (domain.action format)
  invalidServices = lib.filter (s: !testLib.isValidService s) serviceCalls;
  servicesValid =
    if invalidServices != []
    then
      throw ''
        FAIL: Invalid service call formats:
        ${lib.concatStringsSep "\n" (builtins.map (s: "  - ${s}") invalidServices)}
      ''
    else "PASS: All service calls are valid";

  # Test 3: Entity IDs are valid (domain.name format, excluding templates)
  staticEntityIds = lib.filter (e: !(lib.hasInfix "{{" e) && !(lib.hasInfix "{%" e)) entityIds;
  invalidEntityIds = lib.filter (e: !testLib.isValidEntityId e) staticEntityIds;
  entityIdsValid =
    if invalidEntityIds != []
    then
      throw ''
        FAIL: Invalid entity_id formats:
        ${lib.concatStringsSep "\n" (builtins.map (e: "  - ${e}") invalidEntityIds)}
      ''
    else "PASS: All entity IDs are valid";

  # Test 4: Service domains match entity domains (where static)
  # This is a basic check - only for non-templated entity IDs
  # Note: homeassistant.* services work across all entity domains
  incompatibleCalls = let
    checkAction = action:
      if action ? service && action ? target && action.target ? entity_id
      then let
        serviceDomain = testLib.getDomain action.service;
        entityId = action.target.entity_id;
        # Only check static entity IDs
        isStatic = builtins.isString entityId && !(lib.hasInfix "{{" entityId) && !(lib.hasInfix "{%" entityId) && entityId != "all";
      in
        if isStatic
        then let
          entityDomain = testLib.getDomain entityId;
        in
          # Skip domain-agnostic services like homeassistant.turn_on/turn_off
          if serviceDomain != entityDomain && serviceDomain != "homeassistant"
          then [
            {
              inherit serviceDomain entityDomain;
              service = action.service;
              entity = entityId;
            }
          ]
          else []
        else []
      else [];

    intentActions = lib.flatten (lib.mapAttrsToList (_: intent:
      if intent ? action
      then lib.flatten (builtins.map checkAction intent.action)
      else [])
    haConfig.intent_script);

    automationActions = lib.flatten (builtins.map (auto:
      lib.flatten (builtins.map checkAction auto.action))
    haConfig.automation);
  in
    intentActions ++ automationActions;

  serviceDomainCompatibility =
    if incompatibleCalls != []
    then
      throw ''
        FAIL: Service/entity domain mismatches:
        ${lib.concatStringsSep "\n" (builtins.map (c: "  - ${c.service} targeting ${c.entity}") incompatibleCalls)}
      ''
    else "PASS: Service domains match entity domains";
in {
  # Export test results
  inherit
    automationIdsUnique
    servicesValid
    entityIdsValid
    serviceDomainCompatibility
    ;

  # Summary test that fails if any check fails
  all = builtins.deepSeq [
    automationIdsUnique
    servicesValid
    entityIdsValid
    serviceDomainCompatibility
  ] "PASS: All configuration validation tests passed";
}
