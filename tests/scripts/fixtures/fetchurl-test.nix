# Test fixture: Normal fetchurl with intentionally wrong hash
{
  download = fetchurl {
    url = "https://example.com/file.tar.gz";
    # Wrong hash - should be detected and replaced
    hash = "sha256-FETCHURLOLDHASHXXXXXXXXXXXXXXXXXXXXXXXXX123=";
  };

  another_download = fetchurl {
    url = "https://another.org/archive.zip";
    # Wrong hash
    hash = "sha256-ANOTHEROLDHASHXXXXXXXXXXXXXXXXXXXXXXXXXX456=";
  };
}
