# Test fixture: Multiple packages with same old hash (hash collision scenario)
# Script should handle this with context-aware replacement
{
  package_a = fetchFromGitHub {
    owner = "user1";
    repo = "repo-a";
    rev = "v1.0";
    # Same hash as package_b
    hash = "sha256-SAMESAMESAMESAMESAMESAMESAMESAMESAMESAMESAME=";
  };

  package_b = fetchFromGitHub {
    owner = "user2";
    repo = "repo-b";
    rev = "v2.0";
    # Same hash as package_a (collision)
    hash = "sha256-SAMESAMESAMESAMESAMESAMESAMESAMESAMESAMESAME=";
  };

  package_c = fetchFromGitHub {
    owner = "user3";
    repo = "repo-c";
    rev = "v3.0";
    # Different hash
    hash = "sha256-DIFFRENTDIFFRENTDIFFRENTDIFFRENTDIFFRENTDIFF=";
  };
}
