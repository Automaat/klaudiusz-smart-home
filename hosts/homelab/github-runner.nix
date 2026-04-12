{
  config,
  pkgs,
  lib,
  ...
}: let
  runnerUser = "gh-runner-home-nas";
  # NixOS github-runners module hardcodes %S/github-runner/<name> in its
  # configure/unconfigure scripts, so the state path is fixed.
  runnerHome = "/var/lib/github-runner/home-nas";
in {
  users.users.${runnerUser} = {
    isSystemUser = true;
    group = runnerUser;
    home = runnerHome;
    createHome = false;
    shell = pkgs.bashInteractive;
    extraGroups = ["docker"];
  };
  users.groups.${runnerUser} = {};

  services.github-runners.home-nas = {
    enable = true;
    url = "https://github.com/Automaat/home-nas";
    tokenFile = config.sops.secrets."github-runner/home-nas-token".path;
    name = "homelab-home-nas";
    replace = true;
    ephemeral = false;
    extraLabels = ["self-hosted" "home-nas" "linux"];
    extraPackages = with pkgs; [
      git
      openssh
      rsync
      curl
      jq
      ansible
      sops
      age
      python3
      python3Packages.pip
    ];
    user = runnerUser;
    group = runnerUser;
  };

  systemd.services.github-runner-home-nas.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce runnerUser;
    Group = lib.mkForce runnerUser;
    SupplementaryGroups = lib.mkForce ["docker"];
    StateDirectory = lib.mkForce "github-runner/home-nas";
    StateDirectoryMode = lib.mkForce "0750";
    WorkingDirectory = lib.mkForce runnerHome;
    Environment = ["HOME=${runnerHome}"];
    ProtectHome = lib.mkForce false;
  };

  sops.secrets."github-runner/home-nas-token" = {
    mode = "0400";
    owner = runnerUser;
    group = runnerUser;
    restartUnits = ["github-runner-home-nas.service"];
  };

  sops.secrets."github-runner/home-nas-age-key" = {
    mode = "0400";
    owner = runnerUser;
    group = runnerUser;
    path = "${runnerHome}/.config/sops/age/keys.txt";
    restartUnits = ["github-runner-home-nas.service"];
  };

  sops.secrets."github-runner/home-nas-ssh-key" = {
    mode = "0400";
    owner = runnerUser;
    group = runnerUser;
    path = "${runnerHome}/.ssh/id_ed25519";
    restartUnits = ["github-runner-home-nas.service"];
  };

  systemd.tmpfiles.rules = [
    "d ${runnerHome} 0750 ${runnerUser} ${runnerUser} -"
    "d ${runnerHome}/.ssh 0700 ${runnerUser} ${runnerUser} -"
    "d ${runnerHome}/.config 0755 ${runnerUser} ${runnerUser} -"
    "d ${runnerHome}/.config/sops 0755 ${runnerUser} ${runnerUser} -"
    "d ${runnerHome}/.config/sops/age 0700 ${runnerUser} ${runnerUser} -"
  ];
}
