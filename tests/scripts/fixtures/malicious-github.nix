# Test fixture: Attempt Perl code injection via \E escape in owner/repo fields
# This should NOT execute any code or cause the script to fail unsafely
{
  malicious_package_1 = fetchFromGitHub {
    owner = "foo\\E(?{system(\"echo PWNED_OWNER > /tmp/pwned\")})\\Q";
    repo = "bar";
    rev = "abc123def456";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  malicious_package_2 = fetchFromGitHub {
    owner = "normal";
    repo = "evil\\E(?{system(\"echo PWNED_REPO > /tmp/pwned\")})\\Q";
    rev = "def789ghi012";
    hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  };

  # Both owner and repo with injection attempts
  malicious_package_3 = fetchFromGitHub {
    owner = "x\\E(?{die})\\Q";
    repo = "y\\E(?{exit(42)})\\Q";
    rev = "abc000";
    hash = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";
  };
}
