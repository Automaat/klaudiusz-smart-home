{ config, pkgs, lib, ... }:
{
  # === Paperless-ngx Document Management ===
  services.paperless = {
    enable = true;
    address = "0.0.0.0";  # Tailscale access
    port = 28981;

    # Storage
    dataDir = "/var/lib/paperless";
    consumptionDir = "/var/lib/paperless/consume";
    mediaDir = "/var/lib/paperless/media";

    # Secrets
    passwordFile = config.sops.secrets."paperless/admin-password".path;

    settings = {
      PAPERLESS_SECRET_KEY_FILE = config.sops.secrets."paperless/secret-key".path;
      PAPERLESS_OCR_LANGUAGE = "pol+eng";
      PAPERLESS_OCR_MODE = "skip_archive_file";
      PAPERLESS_TIME_ZONE = "Europe/Warsaw";
      PAPERLESS_ENABLE_HTTP_REMOTE_USER = false;
      PAPERLESS_URL = "http://homelab:28981";
    };
  };

  # === PostgreSQL Database ===
  services.postgresql = {
    ensureDatabases = [ "paperless" ];
    ensureUsers = [{
      name = "paperless";
      ensureDBOwnership = true;
    }];
  };

  # === Systemd Hardening + Failure Notifications ===
  systemd.services.paperless-scheduler = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };
  };

  systemd.services.paperless-consumer = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };
  };

  systemd.services.paperless-web = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };
  };
}
