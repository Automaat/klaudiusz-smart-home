#!/usr/bin/env bash
set -euo pipefail

# Fix hash mismatches in fetchFromGitHub calls
# Parses nix flake check errors and automatically updates hashes

echo "Running nix flake check to detect hash mismatches..."
check_output=$(nix flake check -L 2>&1) || true

if ! echo "$check_output" | grep -q "hash mismatch"; then
    echo "No hash mismatches found"
    exit 0
fi

echo "Hash mismatches detected, fixing..."

# Extract hash mismatch errors
# Example error format:
# error: hash mismatch in fixed-output derivation '/nix/store/...-source':
#          specified: sha256-...
#          got:       sha256-...

echo "$check_output" | grep -A2 "hash mismatch" | while IFS= read -r line; do
    if [[ $line =~ "got:"[[:space:]]+(sha256-[A-Za-z0-9+/=]+) ]]; then
        correct_hash="${BASH_REMATCH[1]}"
        echo "Found correct hash: $correct_hash"

        # Find files with hash mismatches
        find . -name "*.nix" -type f -print0 | while IFS= read -r -d '' file; do
            # Check if file contains fetchFromGitHub with wrong hash
            if grep -q "fetchFromGitHub" "$file"; then
                # Replace hash in file
                # Look for hash = "sha256-..." pattern and replace with correct hash
                if grep -q 'hash = "sha256-' "$file"; then
                    # Use sed to replace the hash
                    sed -i.bak "s|hash = \"sha256-[A-Za-z0-9+/=]*\"|hash = \"$correct_hash\"|g" "$file"
                    rm -f "$file.bak"
                    echo "Updated hash in $file"
                fi
            fi
        done
    fi
done

echo "Hash fixing complete"
