#!/usr/bin/env bash
set -euo pipefail

# Fix hash mismatches in fetchFromGitHub calls by prefetching correct hashes

echo "Checking for fetchFromGitHub with outdated hashes..."

# Temp file to track which files were changed
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# Find all .nix files with fetchFromGitHub
find . -name "*.nix" -type f -exec grep -l "fetchFromGitHub" {} \; | while IFS= read -r file; do
    echo "Processing $file..."

    # Read file content and extract fetchFromGitHub blocks
    owner="" repo="" rev="" current_hash=""

    while IFS= read -r line; do
        if [[ $line =~ owner\ =\ \"([^\"]+)\" ]]; then
            owner="${BASH_REMATCH[1]}"
        elif [[ $line =~ repo\ =\ \"([^\"]+)\" ]]; then
            repo="${BASH_REMATCH[1]}"
        elif [[ $line =~ rev\ =\ \"([^\"]+)\" ]]; then
            rev="${BASH_REMATCH[1]}"
        elif [[ $line =~ hash\ =\ \"(sha256-[A-Za-z0-9+/=]+)\" ]]; then
            current_hash="${BASH_REMATCH[1]}"

            # We have a complete block, process it
            if [ -n "$owner" ] && [ -n "$repo" ] && [ -n "$rev" ] && [ -n "$current_hash" ]; then
                echo "  Checking $owner/$repo@$rev"

                # Prefetch the correct hash for this rev
                correct_hash=$(nix-shell -p nix-prefetch-github --run "nix-prefetch-github '$owner' '$repo' --rev '$rev' 2>/dev/null" | grep '"hash"' | sed 's/.*"hash": "\(.*\)".*/\1/' || echo "")

                if [ -z "$correct_hash" ]; then
                    echo "  WARNING: Could not prefetch hash for $owner/$repo@$rev"
                elif [ "$current_hash" != "$correct_hash" ]; then
                    echo "  Hash mismatch:"
                    echo "    Current:  $current_hash"
                    echo "    Correct:  $correct_hash"

                    # Replace the hash in the file
                    if sed -i.bak "s|hash = \"$current_hash\"|hash = \"$correct_hash\"|g" "$file"; then
                        rm -f "$file.bak"
                        echo "  ✓ Updated hash in $file"
                        echo "$file" >> "$tmpfile"
                    fi
                else
                    echo "  ✓ Hash is correct"
                fi

                # Reset for next block
                owner="" repo="" rev="" current_hash=""
            fi
        fi
    done < "$file"
done

changed_files=$(wc -l < "$tmpfile" | tr -d ' ')

echo ""
if [ "$changed_files" -eq 0 ]; then
    echo "No hash changes needed"
else
    echo "Updated hashes in $changed_files file(s)"
fi
