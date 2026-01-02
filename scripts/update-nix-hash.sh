#!/usr/bin/env bash
# Update Nix hash for a fetchzip URL
# Usage: ./scripts/update-nix-hash.sh <file> <url>

set -euo pipefail

FILE="${1:?Missing file path}"
URL="${2:?Missing URL}"

echo "Fetching hash for: $URL"
NEW_HASH=$(nix-prefetch-url --unpack "$URL" 2>/dev/null | xargs nix hash to-sri --type sha256)

echo "New hash: $NEW_HASH"
echo "Updating $FILE..."

# Update the hash in the file (requires GNU sed or BSD sed)
if sed --version 2>/dev/null | grep -q GNU; then
    # GNU sed
    sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$NEW_HASH\";|g" "$FILE"
else
    # BSD sed (macOS)
    sed -i '' "s|hash = \"sha256-[^\"]*\";|hash = \"$NEW_HASH\";|g" "$FILE"
fi

echo "✓ Hash updated in $FILE"
