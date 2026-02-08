{
  pkgs,
  lib,
  python3Packages,
}: rec {
  # Custom Python packages not in nixpkgs
  # Required by auto-discovered Home Assistant integrations

  ibeacon-ble = python3Packages.buildPythonPackage rec {
    pname = "ibeacon-ble";
    version = "1.2.0";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "bluetooth-devices";
      repo = "ibeacon-ble";
      rev = "v${version}";
      hash = "sha256-1liSWxduYpjIMu7226EH4bsc7gca5g/fyL79W4ZMdU4=";
    };

    nativeBuildInputs = with python3Packages; [
      poetry-core
    ];

    propagatedBuildInputs = with python3Packages; [
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

  ha-silabs-firmware-client = python3Packages.buildPythonPackage rec {
    pname = "ha-silabs-firmware-client";
    version = "0.3.0";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://wheels.hass.io/musllinux/ha_silabs_firmware_client-${version}-py3-none-any.whl";
      hash = "sha256-0i/WGZ1kPCY7LRBYbHZ1p+eQAnJATLckfmWPYDIPOsA=";
    };

    propagatedBuildInputs = with python3Packages; [
      aiohttp
      packaging
      yarl
      universal-silabs-flasher
    ];

    pythonImportsCheck = ["ha_silabs_firmware_client"];

    # Tests require additional test dependencies
    doCheck = false;

    meta = with lib; {
      description = "Home Assistant Silicon Labs firmware client";
      homepage = "https://github.com/home-assistant/core";
      license = licenses.asl20;
      maintainers = with maintainers; [];
    };
  };

  kegtron-ble = python3Packages.buildPythonPackage rec {
    pname = "kegtron-ble";
    version = "1.0.2";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "bluetooth-devices";
      repo = "kegtron-ble";
      rev = "v${version}";
      hash = "sha256-aPWf+EHr6Et4OHJ8ZN9M1NxKhaf7piEQilzAsBO3d5E=";
    };

    nativeBuildInputs = with python3Packages; [
      poetry-core
    ];

    propagatedBuildInputs = with python3Packages; [
      bluetooth-sensor-state-data
      sensor-state-data
      bluetooth-data-tools
    ];

    pythonImportsCheck = ["kegtron_ble"];

    # Tests require additional test dependencies
    doCheck = false;

    meta = with lib; {
      description = "Kegtron BLE support";
      homepage = "https://github.com/bluetooth-devices/kegtron-ble";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  };

  json-timeseries = python3Packages.buildPythonPackage rec {
    pname = "json_timeseries";
    # renovate: datasource=pypi depName=json-timeseries
    version = "0.1.7";
    format = "pyproject";

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-Eq3esU2KN0/O96sFaYucxDiA5wfCm8gxA9gEFOKbYCw=";
    };

    nativeBuildInputs = with python3Packages; [
      setuptools
      setuptools-scm
    ];

    propagatedBuildInputs = with python3Packages; [
      python-dateutil
    ];

    pythonImportsCheck = ["json_timeseries"];

    doCheck = false;

    meta = with lib; {
      description = "JSON Time Series data handling library";
      homepage = "https://github.com/slaxor505/json-timeseries-py";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  };

  openplantbook-sdk = python3Packages.buildPythonPackage rec {
    pname = "openplantbook_sdk";
    # renovate: datasource=pypi depName=openplantbook-sdk
    version = "0.4.7";
    format = "pyproject";

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-Pp0lfGnPfy6QZOScU39j/YACLumNJyeHKdbpdFHhdm0=";
    };

    nativeBuildInputs = with python3Packages; [
      setuptools
      setuptools-scm
    ];

    propagatedBuildInputs = [
      python3Packages.aiohttp
      json-timeseries
    ];

    pythonImportsCheck = ["openplantbook_sdk"];

    doCheck = false;

    meta = with lib; {
      description = "Open Plantbook SDK for Python";
      homepage = "https://github.com/slaxor505/openplantbook-sdk-py";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  };

  deepgram-sdk = python3Packages.buildPythonPackage rec {
    pname = "deepgram-sdk";
    # renovate: datasource=pypi depName=deepgram-sdk
    version = "5.3.2";
    format = "pyproject";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/db/03/fe8cf3a3b5fe6d7bfbe8a1230a04e5e057bf391f5747a73aa8c1e8bf96b2/deepgram_sdk-${version}.tar.gz";
      hash = "sha256-vsbpVstL2atZew6pAD1O4dNk1xSmXcAzcvdpqwd2ELM=";
    };

    nativeBuildInputs = with python3Packages; [
      setuptools
    ];

    propagatedBuildInputs = with python3Packages; [
      httpx
      pydantic
      pydantic-core
      typing-extensions
      websockets
    ];

    pythonImportsCheck = ["deepgram"];

    doCheck = false;

    meta = with lib; {
      description = "Deepgram Python SDK for speech recognition";
      homepage = "https://github.com/deepgram/deepgram-python-sdk";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  };
}
