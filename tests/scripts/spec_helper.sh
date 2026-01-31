#!/usr/bin/env bash
# shellspec helper functions

# Setup test environment
setup_test_env() {
    TEST_TMP_DIR=$(mktemp -d)
    export TEST_TMP_DIR
}

# Cleanup test environment
cleanup_test_env() {
    if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

# Mock nix-prefetch-url to return controlled output without network calls
# Usage: mock_nix_prefetch_url "base32hash"
mock_nix_prefetch_url() {
    local hash="$1"
    cat > "$TEST_TMP_DIR/nix-prefetch-url" <<EOF
#!/usr/bin/env bash
echo "path is '/nix/store/mock'"
echo "$hash"
EOF
    chmod +x "$TEST_TMP_DIR/nix-prefetch-url"
    export PATH="$TEST_TMP_DIR:$PATH"
}

# Mock nix hash convert to return controlled SRI hash
# Usage: mock_nix_hash_convert "sha256-SRI"
mock_nix_hash_convert() {
    local sri_hash="$1"
    cat > "$TEST_TMP_DIR/nix" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "hash" ]] && [[ "\$2" == "convert" ]]; then
    echo "$sri_hash"
else
    echo "Mock nix: unexpected command: \$*" >&2
    exit 1
fi
EOF
    chmod +x "$TEST_TMP_DIR/nix"
    export PATH="$TEST_TMP_DIR:$PATH"
}

# Check if file contains injection evidence
check_no_injection() {
    local file="$1"
    # Check for common injection markers
    if [ -f "/tmp/pwned" ]; then
        return 1
    fi
    # Check if process created any suspicious files
    if find /tmp -name "pwned*" -newer "$file" 2>/dev/null | grep -q .; then
        return 1
    fi
    return 0
}
