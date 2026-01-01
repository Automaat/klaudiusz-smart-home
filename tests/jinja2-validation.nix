{
  lib,
  pkgs,
  nixosConfig,
}: let
  haConfig = nixosConfig.services.home-assistant.config;

  # ===========================================
  # Extract Jinja2 Templates
  # ===========================================
  # Collect all Jinja2 templates from config
  extractTemplates = config: let
    # Extract from intent_script speech.text and data fields
    intentTemplates = lib.flatten (
      lib.mapAttrsToList (name: intent: let
        speechTemplate =
          if intent ? speech && intent.speech ? text
          then [{source = "intent_script.${name}.speech.text"; template = intent.speech.text;}]
          else [];
        dataTemplates = lib.flatten (
          if intent ? action
          then
            builtins.map (action:
              if action ? data
              then
                lib.mapAttrsToList (key: value:
                  if builtins.isString value && (lib.hasInfix "{{" value || lib.hasInfix "{%" value)
                  then {source = "intent_script.${name}.action.data.${key}"; template = value;}
                  else null)
                action.data
              else [])
            intent.action
          else []);
      in
        speechTemplate ++ (lib.filter (t: t != null) dataTemplates))
      config.intent_script
    );

    # Extract from automation conditions and actions
    automationTemplates = lib.flatten (
      builtins.map (auto: let
        autoId = auto.id or "unknown";
        conditionTemplates =
          if auto ? condition
          then
            lib.flatten (builtins.map (cond:
              if cond ? value_template
              then [{source = "automation.${autoId}.condition.value_template"; template = cond.value_template;}]
              else [])
            auto.condition)
          else [];
        actionTemplates = lib.flatten (
          if auto ? action
          then
            builtins.map (action:
              if action ? data
              then
                lib.mapAttrsToList (key: value:
                  if builtins.isString value && (lib.hasInfix "{{" value || lib.hasInfix "{%" value)
                  then {source = "automation.${autoId}.action.data.${key}"; template = value;}
                  else null)
                action.data
              else [])
            auto.action
          else []);
      in
        conditionTemplates ++ (lib.filter (t: t != null) actionTemplates))
      config.automation
    );
  in
    intentTemplates ++ automationTemplates;

  templates = extractTemplates haConfig;

  # ===========================================
  # Python Jinja2 Validation Script
  # ===========================================
  validatorScript = pkgs.writeText "validate-jinja2.py" ''
    import sys
    import json
    from jinja2 import Environment, TemplateSyntaxError, meta

    def validate_templates(templates):
        env = Environment()
        errors = []

        for item in templates:
            source = item['source']
            template_str = item['template']

            try:
                # Parse template to check syntax
                env.parse(template_str)
            except TemplateSyntaxError as e:
                errors.append({
                    'source': source,
                    'error': str(e),
                    'template': template_str
                })
            except Exception as e:
                errors.append({
                    'source': source,
                    'error': f"Unexpected error: {str(e)}",
                    'template': template_str
                })

        return errors

    if __name__ == '__main__':
        templates_json = sys.stdin.read()
        templates = json.loads(templates_json)

        errors = validate_templates(templates)

        if errors:
            print("FAIL: Jinja2 template validation errors found:")
            for error in errors:
                print(f"\n  Source: {error['source']}")
                print(f"  Template: {error['template']}")
                print(f"  Error: {error['error']}")
            sys.exit(1)
        else:
            print(f"PASS: All {len(templates)} Jinja2 templates are valid")
            sys.exit(0)
  '';

  # ===========================================
  # Run Jinja2 Validation
  # ===========================================
  jinja2Check = pkgs.runCommand "jinja2-validation" {
    buildInputs = [(pkgs.python3.withPackages (ps: [ps.jinja2]))];
  } ''
    echo "Running Jinja2 template validation..."

    # Convert templates to JSON and pass to Python validator
    echo '${builtins.toJSON templates}' | python3 ${validatorScript} > $TMPDIR/validation_output.txt 2>&1

    if [ $? -eq 0 ]; then
      cat $TMPDIR/validation_output.txt
      echo "PASS: Jinja2 template validation passed" > $out
    else
      cat $TMPDIR/validation_output.txt
      exit 1
    fi
  '';
in {
  inherit jinja2Check templates;

  # Export for use in flake checks
  all = jinja2Check;
}
