# Test fixture: Attempt Perl code injection via \E escape in URL filename
# This should NOT execute any code or cause the script to fail unsafely
{
  malicious_download_1 = fetchurl {
    url = "https://evil.com/file\\E(?{system(\"echo PWNED_URL > /tmp/pwned\")})\\Q.tar.gz";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  malicious_download_2 = fetchurl {
    url = "https://bad.org/tool\\E(?{die(\"injection\")})\\Q-1.0.zip";
    hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  };

  malicious_download_3 = fetchurl {
    url = "https://attacker.net/payload\\E(?{exit(99)})\\Q.tgz";
    hash = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";
  };
}
