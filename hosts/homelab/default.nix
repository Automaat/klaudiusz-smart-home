{
  config,
  pkgs,
  lib,
  ...
}: let
  # Script to publish homeassistant.local mDNS alias
  publishMdnsAlias = pkgs.writeShellScript "publish-mdns-alias" ''
    set -euo pipefail

    # Get default network interface
    iface=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk 'NR==1 {print $5}')

    if [ -z "$iface" ]; then
      echo "avahi-alias-homeassistant: No default network interface found" >&2
      exit 1
    fi

    # Get IPv4 address from interface
    ip_addr=$(${pkgs.iproute2}/bin/ip -4 addr show "$iface" | ${pkgs.gawk}/bin/awk '/inet / {print $2}' | ${pkgs.gnused}/bin/sed 's|/.*||' | head -n1)

    if [ -z "$ip_addr" ]; then
      echo "avahi-alias-homeassistant: No IPv4 address found for interface $iface" >&2
      exit 1
    fi

    # Publish homeassistant.local mDNS alias (use -a -R to avoid reverse lookup collision)
    exec ${pkgs.avahi}/bin/avahi-publish-address -a -R homeassistant.local "$ip_addr"
  '';

  # Cloudflare Tunnel ID
  cloudflareTunnelId = "c0350983-f7b9-4770-ac96-34b8a5184c91";
in {
  imports = [
    ./hardware-configuration.nix
    ./home-assistant
    ./grafana
    ./arr
    ./secrets.nix
    ./users.nix
  ];

  # ===========================================
  # System
  # ===========================================
  system.stateVersion = "24.11";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Enable WireGuard kernel module
  networking.wireguard.enable = true;

  # ===========================================
  # Boot (adjust for your hardware)
  # ===========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network optimization (BBR for better Tailscale performance)
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # ===========================================
  # Networking
  # ===========================================
  networking = {
    hostName = "homelab";
    # Fallback DNS servers (used when Tailscale DNS fails)
    nameservers = ["1.1.1.1" "8.8.8.8"];
    # Disable IPv6 (required for ProtonVPN NAT-PMP)
    enableIPv6 = false;
    networkmanager = {
      enable = true;
      dns = "none"; # Let NixOS manage DNS, not NetworkManager
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        3000 # Grafana
        3001 # Flood (Transmission web UI)
        8123 # Home Assistant
        8096 # Jellyfin
        8989 # Sonarr
        7878 # Radarr
        9696 # Prowlarr
        6767 # Bazarr
        9091 # Transmission RPC
        5055 # Jellyseerr
      ];
      allowedUDPPorts = [
        config.services.tailscale.port # Tailscale
        5353 # mDNS (Avahi/Bonjour for HomeKit discovery)
      ];
      # Allow Tailscale traffic
      trustedInterfaces = ["tailscale0"];
    };
  };

  # ===========================================
  # Locale & Time
  # ===========================================
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl"; # Keep Polish keyboard layout

  # ===========================================
  # Users
  # ===========================================
  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "dialout" "media" "docker"]; # dialout for Zigbee USB, media for Nixarr, docker for training
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMnlSO5YSaF10lrs9q4Z6QJ2LZp4oDHgZ5xR9VaaR+cX skalskimarcin33@gmail.com"
    ];
  };

  # ===========================================
  # Docker
  # ===========================================
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # ===========================================
  # Security
  # ===========================================
  security.sudo.wheelNeedsPassword = false;

  # ===========================================
  # SSH
  # ===========================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ===========================================
  # fail2ban - SSH Protection
  # ===========================================
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"
      "::1"
      "10.0.0.0/8" # Private network (Class A)
      "172.16.0.0/12" # Private network (Class B)
      "192.168.0.0/16" # Private network (Class C)
      "100.64.0.0/10" # Tailscale subnet
    ];
  };

  # ===========================================
  # CrowdSec - Behavioral Intrusion Prevention
  # ===========================================
  services.crowdsec = {
    enable = true;
    localConfig.acquisitions = [
      {
        source = "file";
        filenames = ["/var/lib/hass/home-assistant.log"];
        labels.type = "homeassistant";
      }
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
        labels.type = "syslog";
      }
    ];
  };

  # Enable Local API server (required for agent-LAPI communication)
  services.crowdsec.settings.general.api.server.enable = lib.mkForce true;
  services.crowdsec.settings.lapi.credentialsFile = "/etc/crowdsec/local_api_credentials.yaml";

  # CrowdSec firewall bouncer (nftables/iptables integration)
  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings = {
      update_frequency = "10s";
    };
  };

  # ===========================================
  # Bluetooth
  # ===========================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ===========================================
  # Avahi - mDNS/Bonjour for HomeKit Discovery
  # ===========================================
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS resolution
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      userServices = true;
    };
  };

  # Publish homeassistant.local as alias for Xiaomi integration
  systemd.services.avahi-alias-homeassistant = {
    description = "Publish homeassistant.local mDNS alias";
    after = ["avahi-daemon.service" "network-online.target"];
    wants = ["network-online.target"];
    requires = ["avahi-daemon.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${publishMdnsAlias}";
      Restart = "on-failure";
      RestartSec = "60";
    };
  };

  # ===========================================
  # Tailscale - Secure Remote Access
  # ===========================================
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # ===========================================
  # Cloudflared - External HA Access
  # ===========================================
  services.cloudflared = {
    enable = true;
    tunnels.${cloudflareTunnelId} = {
      credentialsFile = config.sops.secrets."cloudflared/credentials".path;
      default = "http_status:404";
      ingress = {
        "ha.mskalski.dev" = "http://localhost:8123";
      };
    };
  };

  # ===========================================
  # GitOps with Comin
  # ===========================================
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/Automaat/klaudiusz-smart-home.git";
        branches.main.name = "production"; # Only deploys when CI passes
      }
    ];
  };

  # ===========================================
  # ESPHome - ESP32/ESP8266 Firmware Builder
  # ===========================================
  services.esphome = {
    enable = true;
    address = "0.0.0.0"; # Listen on all interfaces
    port = 6052; # Default ESPHome port
    openFirewall = true;
    # Allow access to USB/serial devices for flashing
    allowedDevices = [
      "/dev/ttyUSB0"
      "/dev/ttyUSB1"
      "/dev/ttyACM0"
      "char-usb_device" # All USB devices
    ];
  };

  # ===========================================
  # Monitoring - Prometheus
  # ===========================================
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "365d";
    checkConfig = false; # Disable check - bearer_token_file unavailable at build time

    exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = ["systemd" "textfile"];
      extraFlags = ["--collector.textfile.directory=/var/lib/prometheus-node-exporter-text"];
      openFirewall = false;
    };

    exporters.postgres = {
      enable = true;
      port = 9187;
      openFirewall = false;
      runAsLocalSuperUser = true; # Run as postgres user for socket auth
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{targets = ["localhost:9100"];}];
      }
      {
        job_name = "homeassistant";
        static_configs = [{targets = ["localhost:8123"];}];
        metrics_path = "/api/prometheus";
        bearer_token_file = config.sops.secrets."home-assistant-prometheus-token".path;
      }
      {
        job_name = "postgresql";
        static_configs = [{targets = ["localhost:9187"];}];
      }
      {
        job_name = "prometheus";
        static_configs = [{targets = ["localhost:9090"];}];
      }
      {
        job_name = "grafana";
        static_configs = [{targets = ["localhost:3000"];}];
      }
      {
        job_name = "influxdb";
        static_configs = [{targets = ["localhost:8086"];}];
      }
      {
        job_name = "cloudflared";
        static_configs = [{targets = ["localhost:60123"];}];
        metrics_path = "/metrics";
      }
      {
        job_name = "crowdsec";
        static_configs = [{targets = ["localhost:6060"];}];
      }
    ];
  };

  # ===========================================
  # Service Status Exporter (Textfile Collector)
  # ===========================================
  # Creates directory for textfile metrics
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus-node-exporter-text 0755 prometheus prometheus -"
  ];

  # Periodic service to export monitored service status
  systemd.services.prometheus-service-status = {
    description = "Export service status metrics for Prometheus";
    serviceConfig = {
      Type = "oneshot";
      User = "prometheus";
      ExecStart = pkgs.writeShellScript "export-service-status" ''
        TEXTFILE_DIR="/var/lib/prometheus-node-exporter-text"
        TMPFILE="$TEXTFILE_DIR/service_status.prom.$$"
        OUTFILE="$TEXTFILE_DIR/service_status.prom"

        # Services to monitor
        SERVICES=(
          "fail2ban"
          "crowdsec"
          "crowdsec-firewall-bouncer"
          "cloudflared-tunnel-${cloudflareTunnelId}"
          "wyoming-piper-default"
          "wyoming-faster-whisper-default"
          "tailscaled"
        )

        # Write metrics to temp file
        {
          echo "# HELP service_up Service is running (1) or not (0)"
          echo "# TYPE service_up gauge"
          for service in "''${SERVICES[@]}"; do
            if ${pkgs.systemd}/bin/systemctl is-active "$service.service" >/dev/null 2>&1; then
              echo "service_up{service=\"$service\"} 1"
            else
              echo "service_up{service=\"$service\"} 0"
            fi
          done
        } > "$TMPFILE"

        # Atomic move
        if ! mv "$TMPFILE" "$OUTFILE"; then
          echo "Failed to move metrics file from $TMPFILE to $OUTFILE" >&2
          exit 1
        fi
      '';
    };
  };

  systemd.timers.prometheus-service-status = {
    description = "Timer for service status metrics export";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
    };
  };

  # ===========================================
  # Monitoring - InfluxDB
  # ===========================================
  # Time-series database for Home Assistant entity states
  # 365d retention configured via init service
  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = "127.0.0.1:8086";
      reporting-disabled = true;
    };
  };

  # InfluxDB initialization (org, bucket, user)
  systemd.services.influxdb2-init = {
    description = "Initialize InfluxDB for Home Assistant";
    after = ["influxdb2.service"];
    requires = ["influxdb2.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.influxdb2];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "90s";
      # Load credentials without exposing in argv
      LoadCredential = [
        "password:${config.sops.secrets.influxdb-admin-password.path}"
        "token:${config.sops.secrets.influxdb-admin-token.path}"
      ];
    };
    script = ''
      # Wait for InfluxDB to be ready
      until influx ping &>/dev/null; do
        echo "Waiting for InfluxDB..."
        sleep 1
      done

      # Idempotency: check marker file
      if [ -f /var/lib/influxdb2/.homeassistant-initialized ]; then
        echo "InfluxDB already initialized (marker file present)"
        exit 0
      fi

      # Initial setup with separate password and token
      if influx setup \
        --org homeassistant \
        --bucket home-assistant \
        --username admin \
        --password $(cat "$CREDENTIALS_DIRECTORY/password") \
        --token $(cat "$CREDENTIALS_DIRECTORY/token") \
        --retention 365d \
        --force; then
        touch /var/lib/influxdb2/.homeassistant-initialized
        echo "InfluxDB initialized for Home Assistant"
      else
        echo "InfluxDB initialization failed" >&2
        exit 1
      fi
    '';
  };

  # ===========================================
  # Monitoring - Loki (Log Aggregation)
  # ===========================================
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      server.http_listen_address = "127.0.0.1";
      auth_enabled = false;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem.directory = "/var/lib/loki/chunks";
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        retention_period = "8760h"; # 365 days
        volume_enabled = true; # Enable log volume API for Grafana histogram
        discover_log_levels = true; # Discover log levels for severity coloring
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };
    };
  };

  # ===========================================
  # Monitoring - Promtail (Log Collection)
  # ===========================================
  # Grant promtail user read access to Home Assistant logs
  users.users.promtail.extraGroups = ["hass"];

  # Grant CrowdSec read access to Home Assistant logs and systemd journal
  users.users.crowdsec.extraGroups = ["hass" "systemd-journal"];

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };

      positions.filename = "/var/lib/promtail/positions.yaml";

      clients = [
        {url = "http://localhost:3100/loki/api/v1/push";}
      ];

      scrape_configs = [
        # Home Assistant logs (standard format parsing)
        {
          job_name = "homeassistant";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                job = "homeassistant";
                __path__ = "/var/lib/hass/home-assistant.log";
              };
            }
          ];
          pipeline_stages = [
            {
              regex = {
                expression = "^(?P<timestamp>\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d+) (?P<level>\\w+) \\((?P<thread>\\w+)\\) \\[(?P<logger>[^\\]]+)\\] (?P<message>.*)$";
              };
            }
            {
              labels = {
                level = "";
                logger = "";
              };
            }
            {
              timestamp = {
                source = "timestamp";
                format = "2006-01-02 15:04:05.000";
                location = "Europe/Warsaw";
              };
            }
          ];
        }
        # Systemd journal logs
        {
          job_name = "systemd";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
            {
              source_labels = ["__journal_priority"];
              target_label = "priority";
            }
            {
              source_labels = ["__journal__hostname"];
              target_label = "hostname";
            }
          ];
          # Filter to critical smart home services
          pipeline_stages = [
            {
              match = {
                selector = ''{unit=~"(home-assistant|wyoming-.*|prometheus|grafana|postgresql|influxdb2|crowdsec.*)\\.service"}'';
                stages = [
                  {
                    labels = {
                      service = "";
                    };
                  }
                ];
              };
            }
          ];
        }
      ];
    };
  };

  # Grafana restart limits + failure notification
  systemd.services.grafana = {
    serviceConfig = {
      # Wait 10s between restart attempts
      RestartSec = "10s";
    };
    unitConfig = {
      # Limit restart attempts: 5 tries within 5 minutes, then give up
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      # Send Telegram alert when service fails permanently
      OnFailure = "notify-service-failure@%n.service";
    };
  };

  # ===========================================
  # PostgreSQL Database
  # ===========================================
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = ["hass"];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
    # Explicit authentication - prevents setup hanging
    # https://nixos.wiki/wiki/PostgreSQL
    authentication = pkgs.lib.mkOverride 10 ''
      # Local socket connections (required for setup scripts)
      local all all trust
      # IPv4 local connections
      host all all 127.0.0.1/32 trust
      # IPv6 local connections
      host all all ::1/128 trust
    '';
    # Tuned for 16GB RAM, SSD, Intel Celeron N5095
    settings = {
      shared_buffers = "2GB"; # 25% of RAM for small systems
      effective_cache_size = "8GB"; # 50% of RAM
      maintenance_work_mem = "512MB"; # For VACUUM, etc.
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1; # SSD optimization
      effective_io_concurrency = 200; # SSD
      work_mem = "32MB"; # Per operation
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      jit = "on"; # Enable JIT compilation for complex queries
    };
  };

  # ===========================================
  # Systemd Service Hardening
  # ===========================================
  systemd.services = {
    home-assistant.serviceConfig = {
      # Allow connecting to PostgreSQL via socket
      SupplementaryGroups = ["postgres"];
      # Bluetooth capabilities auto-added by NixOS module for bluetooth components
      # UMask for group-readable log files (640) - allows promtail in hass group to read logs
      UMask = lib.mkForce "0027";
      # StateDirectory permissions already configured in home-assistant/default.nix:317
      Restart = "on-failure";
      RestartSec = "10";
    };
    home-assistant.unitConfig = {
      # Restart limits
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };

    influxdb2.serviceConfig = {
      RestartSec = "10s";
    };
    influxdb2.unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };

    prometheus.serviceConfig = {
      RestartSec = "10s";
    };
    prometheus.unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };

    wyoming-faster-whisper-default.serviceConfig.Restart = "on-failure";
    wyoming-piper-default.serviceConfig.Restart = "on-failure";

    # Promtail - log shipper hardening
    promtail.serviceConfig = {
      # Create state directory for positions.yaml
      StateDirectory = "promtail";
      # Allow reading systemd journal
      SupplementaryGroups = ["systemd-journal"];
      # Restart on failure (resilient to missing log files at startup)
      Restart = "on-failure";
      RestartSec = "10s";
      # Override hardening that blocks journal access
      PrivateMounts = lib.mkForce false;
      MountFlags = lib.mkForce "";
      # Allow reading Home Assistant log file
      ReadOnlyPaths = ["/var/lib/hass"];
    };
    promtail.unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
      OnFailure = "notify-service-failure@%n.service";
    };

    # Telegram notification service template for service failures
    "notify-service-failure@" = {
      description = "Send Telegram notification when %i fails";
      serviceConfig = {
        Type = "oneshot";
        # Load token from file without exposing in argv
        LoadCredential = "ha-token:${config.sops.secrets.home-assistant-prometheus-token.path}";
        # Call Home Assistant notify service via curl with retry logic
        # Retries handle HA restarts during Comin deployments
        ExecStart = ''
          ${pkgs.curl}/bin/curl -X POST \
            --retry 5 \
            --retry-delay 3 \
            --retry-connrefused \
            --retry-all-errors \
            --max-time 30 \
            -H "Authorization: Bearer $(cat $CREDENTIALS_DIRECTORY/ha-token)" \
            -H "Content-Type: application/json" \
            -d '{"message": "⚠️ Service failure: %i exceeded restart limit (5 attempts in 5 min)", "title": "Homelab Alert"}' \
            http://localhost:8123/api/services/notify/telegram
        '';
      };
    };
  };

  # ===========================================
  # Log Rotation (journald)
  # ===========================================
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    SystemMaxFileSize=100M
    MaxRetentionSec=30day
  '';

  # ===========================================
  # Nix Store Maintenance
  # ===========================================
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;

  # ===========================================
  # SSD Optimization
  # ===========================================
  services.fstrim.enable = true; # Weekly TRIM for SSD health

  # ===========================================
  # zram - Compressed RAM swap
  # ===========================================
  zramSwap = {
    enable = true;
    memoryPercent = 25; # 4GB compressed swap from 16GB RAM
  };

  # ===========================================
  # USB devices (Zigbee dongle, etc.)
  # ===========================================
  services.udev.extraRules = ''
    # Zigbee dongles (SONOFF, ConBee, etc.)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", MODE="0666"
    # Coral USB TPU (if using Frigate)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", MODE="0666"
    # Bluetooth USB devices (for HA Bluetooth management)
    # Match Bluetooth class (e0=Wireless, 01=RF, 01=Bluetooth) for any BT adapter
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:e00101:*", MODE="0660", GROUP="dialout"
  '';

  # ===========================================
  # Packages
  # ===========================================
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    jq
    lm_sensors # Temperature monitoring
    age # Age encryption for sops
  ];
}
