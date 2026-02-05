# Test fixture: Normal fetchFromGitHub with intentionally wrong hash
# Used to test that hash replacement works correctly in normal cases
{
  normal_package = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "nixos-unstable";
    # Wrong hash - should be detected and replaced by script
    hash = "sha256-AYqlWrX09+HvGs8zM6ebZ1pwUqjkfpnv8mewYwAo+iM=";
  };

  another_package = fetchFromGitHub {
    owner = "example";
    repo = "test-repo";
    rev = "v1.0.0";
    # Wrong hash
    hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  };
}
