{
  pkgs,
  lib,
  ...
}: {
  # Custom Python packages not in nixpkgs
  # Required by auto-discovered Home Assistant integrations

  ibeacon-ble = pkgs.python3Packages.buildPythonPackage rec {
    pname = "ibeacon-ble";
    version = "1.2.0";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "bluetooth-devices";
      repo = "ibeacon-ble";
      rev = "v${version}";
      hash = "sha256-YDiI2S/FfKc+Cyt/pXJxuWWJcPoMF1INk0rfD0CCutg=";
    };

    nativeBuildInputs = with pkgs.python3Packages; [
      poetry-core
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      aiooui
      home-assistant-bluetooth
      mac-vendor-lookup
    ];

    pythonImportsCheck = ["ibeacon_ble"];

    # Tests require additional test dependencies
    doCheck = false;

    meta = with lib; {
      description = "Parser for iBeacon devices";
      homepage = "https://github.com/bluetooth-devices/ibeacon-ble";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  };

  ha-silabs-firmware-client = pkgs.python3Packages.buildPythonPackage rec {
    pname = "ha-silabs-firmware-client";
    version = "0.3.0";
    format = "pyproject";

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-BqUbcWznNVMxp9r8WaBqvhT/+d5VKs+zN7qgwHLqZvs=";
    };

    nativeBuildInputs = with pkgs.python3Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      aiohttp
      packaging
      yarl
    ];

    pythonImportsCheck = ["ha_silabs_firmware_client"];

    # Tests require additional test dependencies
    doCheck = false;

    meta = with lib; {
      description = "Home Assistant Silicon Labs firmware client";
      homepage = "https://pypi.org/project/ha-silabs-firmware-client/";
      license = licenses.asl20;
      maintainers = with maintainers; [];
    };
  };
}
