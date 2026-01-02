#!/usr/bin/env bash
# Update Nix sha256 hash (e.g. for fetchzip, fetchFromGitHub, fetchurl)
# Usage: ./scripts/update-nix-hash.sh <file> <url>

set -euo pipefail

FILE="${1:?Missing file path}"
URL="${2:?Missing URL}"

if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

echo "Fetching hash for: $URL"
NEW_HASH=$(nix-prefetch-url --unpack "$URL" 2>/dev/null | xargs nix hash to-sri --type sha256)

if [[ -z "$NEW_HASH" || ! "$NEW_HASH" =~ ^sha256- ]]; then
  echo "Error: Failed to fetch valid hash" >&2
  exit 1
fi

echo "New hash: $NEW_HASH"
echo "Updating $FILE..."

# Warn if there are multiple hashes; only the first occurrence will be updated
HASH_COUNT=$(grep -c 'hash = "sha256-' "$FILE" 2>/dev/null || true)
if [ "${HASH_COUNT:-0}" -gt 1 ]; then
  echo "Warning: $FILE contains $HASH_COUNT Nix sha256 hashes; only the first occurrence will be updated." >&2
fi

# Update the hash in the file (requires GNU sed or BSD sed)
if sed --version 2>/dev/null | grep -q GNU; then
  # GNU sed
  sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$NEW_HASH\";|" "$FILE"
else
  # BSD sed (macOS)
  sed -i '' "s|hash = \"sha256-[^\"]*\";|hash = \"$NEW_HASH\";|" "$FILE"
fi

if ! grep -q "hash = \"$NEW_HASH\";" "$FILE"; then
  echo "Error: Failed to update hash in file (pattern not found)" >&2
  exit 1
fi

echo "✓ Hash updated in $FILE"
