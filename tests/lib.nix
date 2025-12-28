# Test helper functions
{lib}: {
  # Extract all intent names from intent_script attribute set
  extractIntentNames = intentScript: builtins.attrNames intentScript;

  # Extract all automation IDs from automation list
  extractAutomationIds = automations:
    builtins.map (auto: auto.id) automations;

  # Check for duplicate values in a list
  findDuplicates = list: let
    counts = lib.foldl' (acc: val:
      acc // {${val} = (acc.${val} or 0) + 1;}) {}
    list;
    duplicates = lib.filterAttrs (_: count: count > 1) counts;
  in
    builtins.attrNames duplicates;

  # Validate entity_id format (should be domain.name)
  isValidEntityId = entityId: let
    parts = lib.splitString "." entityId;
  in
    (builtins.length parts == 2) && (builtins.head parts != "") && (builtins.elemAt parts 1 != "");

  # Validate service format (should be domain.action)
  isValidService = service: let
    parts = lib.splitString "." service;
  in
    (builtins.length parts == 2) && (builtins.head parts != "") && (builtins.elemAt parts 1 != "");

  # Extract domain from entity_id or service
  getDomain = str: builtins.head (lib.splitString "." str);

  # Normalize entity name (lowercase, spaces to underscores)
  normalizeEntityName = name:
    lib.toLower (builtins.replaceStrings [" "] ["_"] name);

  # Test if Jinja2 template is valid (basic check for balanced Jinja2 delimiters)
  isValidJinja2 = template: let
    # Count occurrences of a substring in a string
    countSubstring = pattern: str:
      let
        patLen = builtins.stringLength pattern;
        strLen = builtins.stringLength str;
        go = i:
          if patLen == 0 || i > (strLen - patLen) then
            0
          else
            (if builtins.substring i patLen str == pattern then 1 else 0)
            + go (i + 1);
      in
        if patLen == 0 then 0 else go 0;

    varOpen = countSubstring "{{" template;
    varClose = countSubstring "}}" template;
    blockOpen = countSubstring "{%" template;
    blockClose = countSubstring "%}" template;
  in
    (varOpen == varClose) && (blockOpen == blockClose);
}
