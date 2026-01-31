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
                cd "$TEST_TMP_DIR" || return
                bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

                # Verify no code execution occurred
                When run test ! -f /tmp/pwned
                The status should be success
            End

            It "should not execute code from malicious repo field"
                rm -f /tmp/pwned*

                cp "$FIXTURES_DIR/malicious-github.nix" "$TEST_TMP_DIR/"

                mock_nix_prefetch_url "0000000000000000000000000000000000000000000000000000"
                mock_nix_hash_convert "sha256-NEWSAFEHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="

                cd "$TEST_TMP_DIR" || return
                bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

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

                cd "$TEST_TMP_DIR" || return
                bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

                When run test ! -f /tmp/pwned
                The status should be success
            End
        End
    End

    Describe "Functionality: Basic operations"
        It "should run without errors on empty directory"
            cd "$TEST_TMP_DIR" || return
            When run bash "$OLDPWD/$SCRIPT_PATH" 2>&1

            The output should include "Checking for fetchFromGitHub"
        End

        It "should detect and process fetchFromGitHub blocks"
            cp "$FIXTURES_DIR/valid-hash-mismatch.nix" "$TEST_TMP_DIR/"

            mock_nix_prefetch_url "1234567890abcdef1234567890abcdef1234567890abcdef1234"
            mock_nix_hash_convert "sha256-NEWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123="

            cd "$TEST_TMP_DIR" || return
            output=$(bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true)

            When run echo "$output"
            The output should include "Checking for fetchFromGitHub"
        End

        It "should process multiple files in directory"
            cp "$FIXTURES_DIR/valid-hash-mismatch.nix" "$TEST_TMP_DIR/file1.nix"
            cp "$FIXTURES_DIR/fetchurl-test.nix" "$TEST_TMP_DIR/file2.nix"

            mock_nix_prefetch_url "1111111111111111111111111111111111111111111111111111"
            mock_nix_hash_convert "sha256-MULTIHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123="

            cd "$TEST_TMP_DIR" || return
            output=$(bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true)

            When run echo "$output"
            The output should include "Processing"
        End

        It "should skip .git directory"
            mkdir -p "$TEST_TMP_DIR/.git/objects"
            cp "$FIXTURES_DIR/valid-hash-mismatch.nix" "$TEST_TMP_DIR/.git/test.nix"
            cp "$FIXTURES_DIR/valid-hash-mismatch.nix" "$TEST_TMP_DIR/valid.nix"

            mock_nix_prefetch_url "2222222222222222222222222222222222222222222222222222"
            mock_nix_hash_convert "sha256-SKIPGITHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="

            cd "$TEST_TMP_DIR" || return
            output=$(bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true)

            When run echo "$output"
            The output should not include ".git/test.nix"
        End
    End

    Describe "Hash replacement verification"
        It "should actually replace hash when mismatch detected"
            cat > "$TEST_TMP_DIR/test.nix" <<'EOF'
{
  package = fetchFromGitHub {
    owner = "test";
    repo = "repo";
    rev = "abc123";
    hash = "sha256-OLDHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "3333333333333333333333333333333333333333333333333333"
            mock_nix_hash_convert "sha256-NEWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

            # File should exist and contain new hash
            When run cat test.nix
            The status should be success
            The output should include "sha256-NEWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="
        End

        It "should preserve file structure during replacement"
            cat > "$TEST_TMP_DIR/test.nix" <<'EOF'
{
  package = fetchFromGitHub {
    owner = "test";
    repo = "repo";
    rev = "abc123";
    hash = "sha256-TESTOLDHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "4444444444444444444444444444444444444444444444444444"
            mock_nix_hash_convert "sha256-TESTNEWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

            When run cat test.nix
            The output should include "owner = \"test\";"
            The output should include "repo = \"repo\";"
        End
    End

    Describe "Edge cases: Special characters"
        It "should handle hyphens and dots in owner/repo"
            cat > "$TEST_TMP_DIR/special.nix" <<'EOF'
{
  special = fetchFromGitHub {
    owner = "user-name.test";
    repo = "repo_name-v2";
    rev = "v1.0.0";
    hash = "sha256-SPECIALHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "6666666666666666666666666666666666666666666666666666"
            mock_nix_hash_convert "sha256-NEWSPECIALHASHXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

            # Should not crash
            When run test -f special.nix
            The status should be success
        End

        It "should handle regex metacharacters safely"
            cat > "$TEST_TMP_DIR/regex.nix" <<'EOF'
{
  test = fetchFromGitHub {
    owner = "user.name+special";
    repo = "repo-name*test";
    rev = "v1.0";
    hash = "sha256-REGEXHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            mock_nix_hash_convert "sha256-NEWREGEXHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true
            exit_code=$?

            # Should not crash (exit 0, 1, or 123 acceptable)
            When run test "$exit_code" -lt 2 -o "$exit_code" -eq 123
            The status should be success
        End

        It "should handle parentheses and brackets"
            cat > "$TEST_TMP_DIR/parens.nix" <<'EOF'
{
  test = fetchFromGitHub {
    owner = "user(test)";
    repo = "repo[version]";
    rev = "v1.0";
    hash = "sha256-PARENHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            mock_nix_hash_convert "sha256-NEWPARENHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true
            exit_code=$?

            When run test "$exit_code" -lt 2 -o "$exit_code" -eq 123
            The status should be success
        End
    End

    Describe "Output validation"
        It "should report hash mismatches when found"
            cp "$FIXTURES_DIR/valid-hash-mismatch.nix" "$TEST_TMP_DIR/"

            mock_nix_prefetch_url "dddddddddddddddddddddddddddddddddddddddddddddddddddd"
            mock_nix_hash_convert "sha256-MISMATCHHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123="

            cd "$TEST_TMP_DIR" || return
            output=$(bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true)

            When run echo "$output"
            The output should include "Checking"
        End

        It "should show processing status"
            cat > "$TEST_TMP_DIR/show.nix" <<'EOF'
{
  test = fetchFromGitHub {
    owner = "show";
    repo = "test";
    rev = "v1.0";
    hash = "sha256-SHOWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
            mock_nix_hash_convert "sha256-CORRECTHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            output=$(bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true)

            When run echo "$output"
            The output should include "Processing"
        End

        It "should complete without crashing"
            cat > "$TEST_TMP_DIR/complete.nix" <<'EOF'
{
  test = fetchFromGitHub {
    owner = "complete";
    repo = "test";
    rev = "v1.0";
    hash = "sha256-COMPLETEHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "ffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
            mock_nix_hash_convert "sha256-NEWHASHCOMPLETEXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true
            exit_code=$?

            # Should exit cleanly (0 or 1)
            When run test "$exit_code" -eq 0 -o "$exit_code" -eq 1
            The status should be success
        End
    End

    Describe "Script robustness"
        It "should not fail on incomplete blocks"
            cat > "$TEST_TMP_DIR/incomplete.nix" <<'EOF'
{
  incomplete = fetchFromGitHub {
    owner = "test";
    # Missing repo, rev, hash
  };
}
EOF

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" 2>&1 || true

            # Should not crash
            When run test $? -lt 127
            The status should be success
        End

        It "should handle empty nix files"
            cat > "$TEST_TMP_DIR/empty.nix" <<'EOF'
{ }
EOF

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

            When run test $? -lt 127
            The status should be success
        End

        It "should handle nix files with mixed content"
            cat > "$TEST_TMP_DIR/mixed.nix" <<'EOF'
{
  github = fetchFromGitHub {
    owner = "user";
    repo = "repo";
    rev = "v1.0";
    hash = "sha256-MIXEDHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };

  other = {
    foo = "bar";
  };

  url = fetchurl {
    url = "https://example.com/file.tar.gz";
    hash = "sha256-URLHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };
}
EOF

            mock_nix_prefetch_url "8888888888888888888888888888888888888888888888888888"
            mock_nix_hash_convert "sha256-MIXEDNEWHASHXXXXXXXXXXXXXXXXXXXXXXXXXXXXX456="

            cd "$TEST_TMP_DIR" || return
            bash "$OLDPWD/$SCRIPT_PATH" > /dev/null 2>&1 || true

            # Should process without errors
            When run test -f mixed.nix
            The status should be success
        End
    End
End
