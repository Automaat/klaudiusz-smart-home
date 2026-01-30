#!/usr/bin/env bash
set -euo pipefail

# Fix hash mismatches in fetchFromGitHub and fetchurl calls by prefetching correct hashes

# Temp file to track which files were changed
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

echo "Checking for fetchFromGitHub with outdated hashes..."

# Find all .nix files with fetchFromGitHub, ignoring binaries and .git directory
find . -path './.git' -prune -o -name "*.nix" -type f -exec grep -Il "fetchFromGitHub" {} + | while IFS= read -r file; do
    echo "Processing $file..."

    # Read file content and extract fetchFromGitHub blocks
    owner="" repo="" rev="" current_hash=""

    while IFS= read -r line; do
        if [[ $line =~ owner[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            owner="${BASH_REMATCH[1]}"
        elif [[ $line =~ repo[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            repo="${BASH_REMATCH[1]}"
        elif [[ $line =~ rev[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            rev="${BASH_REMATCH[1]}"
        elif [[ $line =~ hash[[:space:]]*=[[:space:]]*\"(sha256-[A-Za-z0-9+/=]+)\" ]]; then
            current_hash="${BASH_REMATCH[1]}"

            # We have a complete block, process it
            if [ -n "$owner" ] && [ -n "$repo" ] && [ -n "$rev" ] && [ -n "$current_hash" ]; then
                echo "  Checking $owner/$repo@$rev"
                echo "    Current hash: $current_hash"

                # Prefetch the correct hash for this rev using nix-prefetch-url
                # This is more reliable than nix-prefetch-github
                tarball_url="https://github.com/$owner/$repo/archive/$rev.tar.gz"
                echo "    Fetching: $tarball_url"

                # Get hash in base32 format, then convert to SRI
                if base32_hash=$(nix-prefetch-url --unpack "$tarball_url" 2>&1 | tail -1); then
                    echo "    Base32 hash: $base32_hash"

                    # Convert to SRI format
                    if correct_hash=$(nix hash convert --hash-algo sha256 --to sri "$base32_hash" 2>&1); then
                        echo "    Correct hash: $correct_hash"

                        # Validate the format
                        if [[ ! "$correct_hash" =~ ^sha256-[A-Za-z0-9+/=]+$ ]]; then
                            echo "  ⚠️  WARNING: Invalid hash format: $correct_hash"
                            correct_hash=""
                        fi
                    else
                        echo "  ⚠️  WARNING: Failed to convert hash to SRI format: $correct_hash"
                        correct_hash=""
                    fi
                else
                    echo "  ⚠️  WARNING: Failed to prefetch: $base32_hash"
                    correct_hash=""
                fi

                if [ -z "$correct_hash" ]; then
                    echo "  ⚠️  Could not prefetch hash for $owner/$repo@$rev"
                elif [ "$current_hash" != "$correct_hash" ]; then
                    echo "  ❌ Hash mismatch detected!"
                    echo "    Current:  $current_hash"
                    echo "    Correct:  $correct_hash"

                    # Replace the hash in the file
                    if sed -i.bak "s|hash[[:space:]]*=[[:space:]]*\"$current_hash\"|hash = \"$correct_hash\"|g" "$file"; then
                        rm -f "$file.bak"
                        echo "  ✅ Updated hash in $file"
                        echo "$file" >> "$tmpfile"
                    else
                        echo "  ⚠️  Failed to update hash in $file"
                    fi
                else
                    echo "  ✅ Hash is correct"
                fi

                # Reset for next block
                owner="" repo="" rev="" current_hash=""
            fi
        fi
    done < "$file"
done

echo ""
echo "Checking for fetchurl with outdated hashes..."

# Find all .nix files with fetchurl, ignoring binaries and .git directory
find . -path './.git' -prune -o -name "*.nix" -type f -exec grep -Il "fetchurl" {} + | while IFS= read -r file; do
    echo "Processing $file..."

    # Read file content and extract fetchurl blocks
    current_url="" current_hash=""

    while IFS= read -r line; do
        # Match URL patterns
        if [[ $line =~ url[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            current_url="${BASH_REMATCH[1]}"
        # Match hash patterns
        elif [[ $line =~ hash[[:space:]]*=[[:space:]]*\"(sha256-[A-Za-z0-9+/=]+)\" ]]; then
            current_hash="${BASH_REMATCH[1]}"

            # We have a complete block, process it
            if [ -n "$current_url" ] && [ -n "$current_hash" ]; then
                echo "  Checking URL: $current_url"
                echo "    Current hash: $current_hash"

                # Determine if we need --unpack flag based on file extension
                unpack_flag=""
                if [[ "$current_url" =~ \.(tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz|zip)$ ]]; then
                    unpack_flag="--unpack"
                fi

                # Prefetch the correct hash
                echo "    Fetching: $current_url"

                # Get hash in base32 format, then convert to SRI
                if base32_hash=$(nix-prefetch-url $unpack_flag "$current_url" 2>&1 | tail -1); then
                    echo "    Base32 hash: $base32_hash"

                    # Convert to SRI format
                    if correct_hash=$(nix hash convert --hash-algo sha256 --to sri "$base32_hash" 2>&1); then
                        echo "    Correct hash: $correct_hash"

                        # Validate the format
                        if [[ ! "$correct_hash" =~ ^sha256-[A-Za-z0-9+/=]+$ ]]; then
                            echo "  ⚠️  WARNING: Invalid hash format: $correct_hash"
                            correct_hash=""
                        fi
                    else
                        echo "  ⚠️  WARNING: Failed to convert hash to SRI format: $correct_hash"
                        correct_hash=""
                    fi
                else
                    echo "  ⚠️  WARNING: Failed to prefetch: $base32_hash"
                    correct_hash=""
                fi

                if [ -z "$correct_hash" ]; then
                    echo "  ⚠️  Could not prefetch hash for $current_url"
                elif [ "$current_hash" != "$correct_hash" ]; then
                    echo "  ❌ Hash mismatch detected!"
                    echo "    Current:  $current_hash"
                    echo "    Correct:  $correct_hash"

                    # Replace the hash in the file
                    if sed -i.bak "s|hash[[:space:]]*=[[:space:]]*\"$current_hash\"|hash = \"$correct_hash\"|g" "$file"; then
                        rm -f "$file.bak"
                        echo "  ✅ Updated hash in $file"
                        echo "$file" >> "$tmpfile"
                    else
                        echo "  ⚠️  Failed to update hash in $file"
                    fi
                else
                    echo "  ✅ Hash is correct"
                fi

                # Reset for next block
                current_url="" current_hash=""
            fi
        fi
    done < "$file"
done

changed_files=$(sort -u "$tmpfile" | wc -l | tr -d ' ')

echo ""
if [ "$changed_files" -eq 0 ]; then
    echo "No hash changes needed"
else
    echo "Updated hashes in $changed_files file(s)"
fi
