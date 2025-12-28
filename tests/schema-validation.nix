{
  lib,
  pkgs,
  nixosConfig,
}: let
  testLib = import ./lib.nix {inherit lib;};
  haConfig = nixosConfig.services.home-assistant.config;

  # =============================================
  # YAML Validation
  # =============================================

  # Validate YAML syntax using yq
  yamlSyntaxCheck =
    pkgs.runCommand "yaml-syntax-check" {
      buildInputs = [pkgs.yq-go];
    } ''
      echo "Validating custom_sentences YAML syntax..."
      if yq eval '.' ${../custom_sentences/pl/intents.yaml} > /dev/null; then
        echo "PASS: YAML syntax is valid" > $out
      else
        echo "FAIL: YAML syntax errors" > $out
        exit 1
      fi
    '';

  # =============================================
  # Intent Script Structure Validation
  # =============================================

  # Check that all intent scripts have either speech.text or action
  validateIntentStructure = let
    intents = haConfig.intent_script;
    invalidIntents = lib.filterAttrs (name: intent:
      !(intent ? speech || intent ? action))
    intents;
  in
    if invalidIntents != {}
    then
      throw ''
        FAIL: Intents without speech or action:
        ${lib.concatStringsSep "\n" (builtins.map (name: "  - ${name}") (builtins.attrNames invalidIntents))}
      ''
    else "PASS: All intents have speech or action";

  # =============================================
  # Jinja2 Template Validation
  # =============================================

  # Collect all templates from speech.text and data fields
  collectTemplates = config: let
    speechTemplates = lib.mapAttrsToList (_: intent:
      if intent ? speech && intent.speech ? text
      then intent.speech.text
      else null)
    config.intent_script;

    dataTemplates = lib.flatten (
      lib.mapAttrsToList (_: intent:
        if intent ? action
        then
          lib.flatten (builtins.map (action:
            if action ? data
            then lib.attrValues action.data
            else [])
          intent.action)
        else [])
      config.intent_script
    );

    allTemplates = speechTemplates ++ dataTemplates;
  in
    lib.filter (t: t != null && builtins.isString t) allTemplates;

  templates = collectTemplates haConfig;

  # Basic Jinja2 validation (balanced braces)
  invalidTemplates = lib.filter (t: !testLib.isValidJinja2 t) templates;
  jinja2Valid =
    if invalidTemplates != []
    then
      throw ''
        FAIL: Templates with unbalanced braces:
        ${lib.concatStringsSep "\n" (builtins.map (t: "  - ${t}") invalidTemplates)}
      ''
    else "PASS: All Jinja2 templates have balanced braces";

  # =============================================
  # Home Assistant Schema Validation
  # =============================================

  # Known valid HA service domains
  validDomains = [
    "light"
    "climate"
    "cover"
    "media_player"
    "lock"
    "fan"
    "homeassistant"
    "persistent_notification"
    "notify"
    "automation"
    "script"
    "scene"
    "switch"
    "input_boolean"
    "input_number"
  ];

  # Collect all service calls
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

  serviceCalls = collectServiceCalls haConfig;

  # Check that all service domains are known
  unknownDomains = let
    domains = lib.unique (builtins.map testLib.getDomain serviceCalls);
    unknown = lib.filter (d: !builtins.elem d validDomains) domains;
  in
    unknown;

  serviceDomainsKnown =
    if unknownDomains != []
    then
      builtins.trace
      ''
        WARNING: Unknown service domains (may be valid):
        ${lib.concatStringsSep "\n" (builtins.map (d: "  - ${d}") unknownDomains)}
      ''
      "PASS: Service domain check completed (with warnings)"
    else "PASS: All service domains are known";

  # =============================================
  # Data Type Validation
  # =============================================

  # Check brightness_pct is 0-100 (if static)
  validateBrightnessValues = let
    collectBrightness = config:
      lib.flatten (
        lib.mapAttrsToList (_: intent:
          if intent ? action
          then
            lib.flatten (builtins.map (action:
              if action ? data && action.data ? brightness_pct
              then [action.data.brightness_pct]
              else [])
            intent.action)
          else [])
        config.intent_script
      );

    brightnessValues = collectBrightness haConfig;
    staticValues = lib.filter (v: builtins.isInt v || (builtins.isString v && !(lib.hasInfix "{{" v))) brightnessValues;
    intValues = builtins.map (v:
      if builtins.isInt v
      then v
      else lib.toInt v)
    (lib.filter builtins.isInt staticValues);
    invalid = lib.filter (v: v < 0 || v > 100) intValues;
  in
    if invalid != []
    then
      throw ''
        FAIL: brightness_pct values out of range (0-100):
        ${lib.concatStringsSep "\n" (builtins.map (v: "  - ${toString v}") invalid)}
      ''
    else "PASS: All brightness_pct values are valid";

  # =============================================
  # YAML Content Validation
  # =============================================

  # Check that YAML language is set to "pl" (build-time check)
  yamlLanguageCheck =
    pkgs.runCommand "yaml-lang-check" {
      buildInputs = [pkgs.yq-go];
    } ''
      echo "Checking YAML language setting..."
      lang=$(yq eval '.language' ${../custom_sentences/pl/intents.yaml})
      if [ "$lang" != "pl" ]; then
        echo "FAIL: YAML language should be 'pl', got '$lang'"
        exit 1
      fi
      echo "PASS: YAML language is correctly set to 'pl'" > $out
    '';

  # =============================================
  # YAML Intent Matching Validation
  # =============================================

  # Check that all YAML intents exist in Nix config (build-time check)
  yamlIntentMatchCheck =
    pkgs.runCommand "yaml-intent-match-check" {
      buildInputs = [pkgs.yq-go pkgs.jq];
      nixIntents = builtins.toJSON (builtins.attrNames haConfig.intent_script);
    } ''
      echo "Checking YAML intents match Nix intents..."

      # Extract YAML intent names
      yaml_intents=$(yq eval '.intents | keys' -o=json ${../custom_sentences/pl/intents.yaml})

      # Compare with Nix intents
      echo "$yaml_intents" | jq -r '.[]' | while read intent; do
        if ! echo "$nixIntents" | jq -e --arg i "$intent" 'index($i)' > /dev/null; then
          echo "ERROR: Intent '$intent' defined in YAML but missing in intents.nix"
          exit 1
        fi
      done

      echo "PASS: All YAML intents exist in Nix" > $out
    '';

  # Evaluation-time summary test
  evalTests = builtins.deepSeq [
    validateIntentStructure
    jinja2Valid
    serviceDomainsKnown
    validateBrightnessValues
  ] "PASS: Evaluation-time schema validation tests passed";
in {
  # Export test results (evaluation-time)
  inherit
    validateIntentStructure
    jinja2Valid
    serviceDomainsKnown
    validateBrightnessValues
    evalTests
    ;

  # Export test results (build-time derivations)
  inherit
    yamlSyntaxCheck
    yamlLanguageCheck
    yamlIntentMatchCheck
    ;

  # Build-time summary test (combines all derivations)
  all =
    pkgs.runCommand "all-schema-validation-tests" {
      evalResult = evalTests;
    } ''
      echo "Running all schema validation tests..."
      cat ${yamlSyntaxCheck}
      cat ${yamlLanguageCheck}
      cat ${yamlIntentMatchCheck}
      echo "$evalResult"
      echo "PASS: All schema validation tests passed" > $out
    '';
}
