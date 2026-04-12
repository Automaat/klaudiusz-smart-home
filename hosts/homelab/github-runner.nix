{
  config,
  pkgs,
  lib,
  ...
}: let
  runnerUser = "gh-runner-home-nas";
  # NixOS github-runners module hardcodes %S/github-runner/<name> in its
  # configure/unconfigure/setup-work-dirs scripts, so the state path is fixed.
  runnerHome = "/var/lib/github-runner/home-nas";
  ageKeyFile = "/run/secrets/github-runner/home-nas-age-key";
  sshKeyFile = "/run/secrets/github-runner/home-nas-ssh-key";
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
    extraEnvironment = {
      # sops decrypt in playbooks: delegate_to: localhost reads SOPS_AGE_KEY_FILE
      SOPS_AGE_KEY_FILE = ageKeyFile;
      # ansible-playbook ssh connections: read private key from /run/secrets,
      # avoids copying it onto disk in $HOME.
      ANSIBLE_PRIVATE_KEY_FILE = sshKeyFile;
      ANSIBLE_HOST_KEY_CHECKING = "False";
    };
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
    restartUnits = ["github-runner-home-nas.service"];
  };

  sops.secrets."github-runner/home-nas-ssh-key" = {
    mode = "0400";
    owner = runnerUser;
    group = runnerUser;
    restartUnits = ["github-runner-home-nas.service"];
  };
}
