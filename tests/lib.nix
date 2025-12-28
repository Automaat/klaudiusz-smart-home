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

  # Test if Jinja2 template is valid (basic check for balanced braces)
  isValidJinja2 = template: let
    openCount = lib.count (c: c == "{") (lib.stringToCharacters template);
    closeCount = lib.count (c: c == "}") (lib.stringToCharacters template);
  in
    openCount == closeCount;
}
