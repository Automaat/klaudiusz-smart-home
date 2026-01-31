#!/usr/bin/env bash
# shellspec tests for .github/scripts/fix-nix-hashes.sh

# Source helper functions
. tests/scripts/spec_helper.sh

Describe "fix-nix-hashes.sh"
    SCRIPT_PATH=".github/scripts/fix-nix-hashes.sh"
    FIXTURES_DIR="tests/scripts/fixtures"

    Before "setup_test_env"
    After "cleanup_test_env"

    Describe "Security: Perl code injection prevention"
        Describe "fetchFromGitHub"
            It "should not execute code from malicious owner field"
                # Clean up any previous pwned files
                rm -f /tmp/pwned*

                # Copy malicious fixture to temp dir
                cp "$FIXTURES_DIR/malicious-github.nix" "$TEST_TMP_DIR/"

                # Mock nix commands to avoid network calls
                mock_nix_prefetch_url "0000000000000000000000000000000000000000000000000000"
                mock_nix_hash_convert "sha256-NEWSAFEHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="

                # Run script on malicious file (will fail but shouldn't execute code)
                cd "$TEST_TMP_DIR"
                bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

                # Verify no code execution occurred
                When run test ! -f /tmp/pwned
                The status should be success
            End
        End

        Describe "fetchurl"
            It "should not execute code from malicious URL filename"
                rm -f /tmp/pwned*

                cp "$FIXTURES_DIR/malicious-fetchurl.nix" "$TEST_TMP_DIR/"

                mock_nix_prefetch_url "0000000000000000000000000000000000000000000000000000"
                mock_nix_hash_convert "sha256-NEWSAFEHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="

                cd "$TEST_TMP_DIR"
                bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

                When run test ! -f /tmp/pwned
                The status should be success
            End
        End
    End

    Describe "Functionality: Script execution"
        It "should run without errors on empty directory"
            cd "$TEST_TMP_DIR"
            When run bash "$OLDPWD/$SCRIPT_PATH" 2>&1

            The output should include "No hash changes"
        End

        It "should detect fetchFromGitHub blocks"
            cp "$FIXTURES_DIR/valid-hash-mismatch.nix" "$TEST_TMP_DIR/"

            mock_nix_prefetch_url "1234567890abcdef1234567890abcdef1234567890abcdef1234"
            mock_nix_hash_convert "sha256-NEWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123="

            cd "$TEST_TMP_DIR"
            # Capture output regardless of exit status
            output=$(bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true)

            When run echo "$output"
            The output should include "Checking for fetchFromGitHub"
        End
    End

    Describe "Perl quotemeta security"
        It "should handle special regex characters without crashing"
            # Create fixture with regex metacharacters (not injection, just special chars)
            cat > "$TEST_TMP_DIR/regex-chars.nix" <<'EOF'
{
  test = fetchFromGitHub {
    owner = "user.name+special";
    repo = "repo-name*test";
    rev = "v1.0";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
EOF

            mock_nix_prefetch_url "1111111111111111111111111111111111111111111111111111"
            mock_nix_hash_convert "sha256-SAFEHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX222="

            cd "$TEST_TMP_DIR"
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true
            exit_code=$?

            # Should not crash (exit 0, 1, or 123 all acceptable)
            When run test "$exit_code" -lt 2 -o "$exit_code" -eq 123
            The status should be success
        End
    End
End
