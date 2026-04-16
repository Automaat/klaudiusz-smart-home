{config, ...}: {
  # ===========================================
  # Grafana Configuration
  # ===========================================
  # Accessible on local network (192.168.0.241:3000) and Tailscale
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0"; # Bind to all interfaces (Tailscale can access)
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
      };
    };
    provision = {
      enable = true;

      # Datasources
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
          uid = "prometheus"; # Explicit UID for dashboard references
        }
        {
          name = "InfluxDB";
          type = "influxdb";
          url = "http://localhost:8086";
          uid = "influxdb";
          jsonData = {
            version = "Flux"; # InfluxDB 2.x uses Flux query language
            organization = "homeassistant";
            defaultBucket = "home-assistant";
            tlsSkipVerify = true;
          };
          secureJsonData = {
            token = "$__file{${config.sops.secrets.influxdb-admin-token.path}}";
          };
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
          uid = "loki";
          isDefault = false;
          jsonData = {
            maxLines = 1000;
            # Enable time range boundaries for Grafana Explore
            timeout = "60s";
            # Derived fields for log drilldown (trace ID linking, etc.)
            derivedFields = [];
          };
        }
      ];

      # Dashboard Provisioning
      dashboards.settings.providers = [
        {
          name = "Infrastructure";
          disableDeletion = true; # Prevent GUI deletion
          options = {
            path = ./dashboards/infrastructure;
            foldersFromFilesStructure = true;
          };
        }
        {
          name = "Smart Home";
          disableDeletion = true;
          options = {
            path = ./dashboards/smart-home;
            foldersFromFilesStructure = true;
          };
        }
        {
          name = "Services";
          disableDeletion = true;
          options = {
            path = ./dashboards/services;
            foldersFromFilesStructure = true;
          };
        }
      ];

      # Alerting Provisioning
      alerting = {
        contactPoints.settings.contactPoints = [
          {
            name = "Home Assistant Telegram";
            receivers = [
              {
                uid = "ha_telegram";
                type = "webhook";
                settings = {
                  url = "http://localhost:8123/api/webhook/grafana_systemd_alerts";
                  httpMethod = "POST";
                };
                disableResolveMessage = false;
              }
            ];
          }
        ];

        rules.settings.groups = [
          {
            name = "systemd_services";
            folder = "Services";
            interval = "1m";
            rules = let
              mkSystemdAlertRule = {
                serviceName,
                unitName,
                title,
                summary,
                description,
                severity ? "warning",
              }: {
                uid = "${serviceName}_down";
                inherit title;
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "prometheus";
                    model = {
                      expr = ''node_systemd_unit_state{name="${unitName}",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      reducer = "max";
                      refId = "B";
                      type = "reduce";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "B";
                      refId = "C";
                      type = "threshold";
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "Error";
                for = "10m";
                annotations = {
                  inherit summary description;
                };
                labels = {
                  inherit severity;
                  service = serviceName;
                };
                isPaused = false;
              };

              services = [
                # Critical services - alert if failed for more than 10 minutes
                {
                  serviceName = "home_assistant";
                  unitName = "home-assistant.service";
                  title = "Home Assistant Service Down";
                  summary = "Home Assistant service is not running";
                  description = "The home-assistant.service has been inactive for more than 10 minutes. Check: systemctl status home-assistant";
                  severity = "critical";
                }
                {
                  serviceName = "postgresql";
                  unitName = "postgresql.service";
                  title = "PostgreSQL Service Down";
                  summary = "PostgreSQL service is not running";
                  description = "The postgresql.service has been inactive for more than 10 minutes. Check: systemctl status postgresql";
                  severity = "critical";
                }
                {
                  serviceName = "prometheus";
                  unitName = "prometheus.service";
                  title = "Prometheus Service Down";
                  summary = "Prometheus service is not running";
                  description = "The prometheus.service has been inactive for more than 10 minutes. Metrics collection and alerting stopped. Check: systemctl status prometheus";
                  severity = "critical";
                }
                # Warning services
                {
                  serviceName = "whisper";
                  unitName = "wyoming-faster-whisper-default.service";
                  title = "Whisper STT Service Down";
                  summary = "Whisper STT service is not running";
                  description = "The wyoming-faster-whisper-default.service has been inactive for more than 10 minutes. Voice commands will not work. Check: systemctl status wyoming-faster-whisper-default";
                }
                {
                  serviceName = "piper";
                  unitName = "wyoming-piper-default.service";
                  title = "Piper TTS Service Down";
                  summary = "Piper TTS service is not running";
                  description = "The wyoming-piper-default.service has been inactive for more than 10 minutes. Voice responses will not work. Check: systemctl status wyoming-piper-default";
                }
                {
                  serviceName = "tailscale";
                  unitName = "tailscaled.service";
                  title = "Tailscale Service Down";
                  summary = "Tailscale service is not running";
                  description = "The tailscaled.service has been inactive for more than 10 minutes. Remote access via Tailscale will not work. Check: systemctl status tailscaled";
                }
                {
                  serviceName = "grafana";
                  unitName = "grafana.service";
                  title = "Grafana Service Down";
                  summary = "Grafana service is not running";
                  description = "The grafana.service has been inactive for more than 10 minutes. Dashboards and monitoring UI unavailable. Check: systemctl status grafana";
                }
                {
                  serviceName = "influxdb";
                  unitName = "influxdb2.service";
                  title = "InfluxDB Service Down";
                  summary = "InfluxDB service is not running";
                  description = "The influxdb2.service has been inactive for more than 10 minutes. Time-series data collection stopped. Check: systemctl status influxdb2";
                }
                {
                  serviceName = "fail2ban";
                  unitName = "fail2ban.service";
                  title = "fail2ban Service Down";
                  summary = "fail2ban service is not running";
                  description = "The fail2ban.service has been inactive for more than 10 minutes. SSH brute-force protection disabled. Check: systemctl status fail2ban";
                }
                {
                  serviceName = "crowdsec";
                  unitName = "crowdsec.service";
                  title = "CrowdSec Service Down";
                  summary = "CrowdSec service is not running";
                  description = "The crowdsec.service has been inactive for more than 10 minutes. Behavioral intrusion prevention disabled. Check: systemctl status crowdsec";
                }
                {
                  serviceName = "cloudflared";
                  unitName = "cloudflared-tunnel-c0350983-f7b9-4770-ac96-34b8a5184c91.service";
                  title = "Cloudflared Tunnel Down";
                  summary = "Cloudflared tunnel is not running";
                  description = "The cloudflared-tunnel service has been inactive for more than 10 minutes. External access via ha.mskalski.dev unavailable. Check: systemctl status cloudflared-tunnel-*";
                }
              ];
            in
              map mkSystemdAlertRule services;
          }

          # Prometheus scrape health monitoring
          {
            name = "prometheus_scrape_health";
            folder = "Services";
            interval = "1m";
            rules = [
              {
                uid = "node_exporter_down";
                title = "Node Exporter Scrape Failing";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "prometheus";
                    model = {
                      expr = ''up{job="node"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      reducer = "max";
                      refId = "B";
                      type = "reduce";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "B";
                      refId = "C";
                      type = "threshold";
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "5m";
                annotations = {
                  summary = "Prometheus cannot scrape node_exporter metrics";
                  description = "The node_exporter target has been down for more than 5 minutes. Systemd service metrics unavailable. Check: systemctl status prometheus-node-exporter";
                };
                labels = {
                  severity = "critical";
                  service = "prometheus_scraping";
                };
                isPaused = false;
              }
            ];
          }

          # Security Services Monitoring
          {
            name = "security_services";
            folder = "Services";
            interval = "1m";
            rules = [
              {
                uid = "cloudflared_high_error_rate";
                title = "Cloudflared High Error Rate";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "prometheus";
                    model = {
                      expr = ''rate(cloudflared_tunnel_requests_total{status=~"5.."}[5m]) / clamp_min(rate(cloudflared_tunnel_requests_total[5m]), 1) * 100'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      reducer = "max";
                      refId = "B";
                      type = "reduce";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "B";
                      refId = "C";
                      type = "threshold";
                      conditions = [
                        {
                          evaluator = {
                            params = [5];
                            type = "gt";
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "OK";
                for = "5m";
                annotations = {
                  summary = "Cloudflared tunnel error rate above 5%";
                  description = "The Cloudflared tunnel error rate has been above 5% for more than 5 minutes. Check: journalctl -u cloudflared-tunnel-* -n 50";
                };
                labels = {
                  severity = "warning";
                  service = "cloudflared";
                };
                isPaused = false;
              }
              {
                uid = "crowdsec_high_ban_rate";
                title = "CrowdSec High Ban Rate";
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "prometheus";
                    model = {
                      expr = ''rate(cs_bucket_pours_total[1m]) * 60'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      reducer = "max";
                      refId = "B";
                      type = "reduce";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 300;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "B";
                      refId = "C";
                      type = "threshold";
                      conditions = [
                        {
                          evaluator = {
                            params = [10];
                            type = "gt";
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "OK";
                execErrState = "OK";
                for = "5m";
                annotations = {
                  summary = "CrowdSec ban rate exceeds 10 per minute";
                  description = "CrowdSec is triggering more than 10 decisions per minute for over 5 minutes. Possible attack in progress. Check: cscli decisions list";
                };
                labels = {
                  severity = "warning";
                  service = "crowdsec";
                };
                isPaused = false;
              }
            ];
          }

          # ===========================================
          # Home NAS Health
          # ===========================================
          {
            name = "home_nas_health";
            folder = "Services";
            interval = "1m";
            rules = let
              mkPromExprAlertRule = {
                uid,
                title,
                expr,
                thresholdType ? "lt",
                thresholdValue,
                forDuration ? "5m",
                summary,
                description,
                severity ? "warning",
                noDataState ? "OK",
              }: {
                inherit uid title;
                condition = "C";
                data = [
                  {
                    refId = "A";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "prometheus";
                    model = {
                      inherit expr;
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
                    };
                  }
                  {
                    refId = "B";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      reducer = "max";
                      refId = "B";
                      type = "reduce";
                    };
                  }
                  {
                    refId = "C";
                    relativeTimeRange = {
                      from = 600;
                      to = 0;
                    };
                    datasourceUid = "-100";
                    model = {
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "B";
                      refId = "C";
                      type = "threshold";
                      conditions = [
                        {
                          evaluator = {
                            params = [thresholdValue];
                            type = thresholdType;
                          };
                        }
                      ];
                    };
                  }
                ];
                inherit noDataState;
                execErrState = "Error";
                "for" = forDuration;
                annotations = {
                  inherit summary description;
                };
                labels = {
                  inherit severity;
                  service = "home_nas";
                  site = "home-nas";
                };
                isPaused = false;
              };
              perInstanceServices = [
                {
                  key = "sonarr";
                  name = "Sonarr";
                  instance = "192.168.20.192:9707";
                  job = "home-nas-exportarr";
                  severity = "warning";
                }
                {
                  key = "radarr";
                  name = "Radarr";
                  instance = "192.168.20.192:9708";
                  job = "home-nas-exportarr";
                  severity = "warning";
                }
                {
                  key = "lidarr";
                  name = "Lidarr";
                  instance = "192.168.20.192:9709";
                  job = "home-nas-exportarr";
                  severity = "warning";
                }
                {
                  key = "prowlarr";
                  name = "Prowlarr";
                  instance = "192.168.20.192:9710";
                  job = "home-nas-exportarr";
                  severity = "warning";
                }
                {
                  key = "bazarr";
                  name = "Bazarr";
                  instance = "192.168.20.192:9711";
                  job = "home-nas-exportarr";
                  severity = "warning";
                }
                {
                  key = "qbittorrent";
                  name = "qBittorrent";
                  instance = "192.168.40.162:9102";
                  job = "home-nas-qbittorrent";
                  severity = "warning";
                }
                {
                  key = "immich_redis";
                  name = "Immich Redis";
                  instance = "192.168.20.191:9121";
                  job = "home-nas-valkey";
                  severity = "critical";
                }
                {
                  key = "nextcloud_redis";
                  name = "Nextcloud Redis";
                  instance = "192.168.20.106:9121";
                  job = "home-nas-valkey";
                  severity = "critical";
                }
                {
                  key = "paperless_redis";
                  name = "Paperless Redis";
                  instance = "192.168.20.106:9122";
                  job = "home-nas-valkey";
                  severity = "critical";
                }
                {
                  key = "immich";
                  name = "Immich";
                  instance = "192.168.20.191:8081";
                  job = "home-nas-immich";
                  severity = "critical";
                }
                {
                  key = "sybra";
                  name = "Sybra";
                  instance = "192.168.20.219:8080";
                  job = "home-nas-sybra";
                  severity = "critical";
                }
              ];
              mkInstanceDownRule = svc:
                mkPromExprAlertRule {
                  uid = "home_nas_${svc.key}_down";
                  title = "Home NAS ${svc.name} Down";
                  expr = ''up{job="${svc.job}",instance="${svc.instance}"}'';
                  thresholdType = "lt";
                  thresholdValue = 1;
                  forDuration = "5m";
                  summary = "${svc.name} exporter is down";
                  description = "${svc.name} exporter (${svc.instance}) has been down for 5+ minutes. Check the service and its container.";
                  severity = svc.severity;
                };
            in
              [
                (mkPromExprAlertRule {
                  uid = "home_nas_node_down";
                  title = "Home NAS Host Down";
                  expr = ''up{job="home-nas-node"}'';
                  thresholdType = "lt";
                  thresholdValue = 1;
                  forDuration = "5m";
                  summary = "A home-nas host is unreachable";
                  description = "node_exporter on a home-nas host has been down for 5+ minutes. Check Proxmox and the affected LXC/VM.";
                  severity = "critical";
                  noDataState = "Alerting";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_cadvisor_down";
                  title = "Home NAS cAdvisor Down";
                  expr = ''up{job="home-nas-cadvisor"}'';
                  thresholdType = "lt";
                  thresholdValue = 1;
                  forDuration = "10m";
                  summary = "cAdvisor on a home-nas docker host is down";
                  description = "Container metrics unavailable from a home-nas host for 10+ minutes. Check the monitoring-agents stack on that host.";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_postgres_down";
                  title = "Home NAS Postgres Down";
                  expr = ''up{job="home-nas-postgres"}'';
                  thresholdType = "lt";
                  thresholdValue = 1;
                  forDuration = "5m";
                  summary = "A postgres-exporter on home-nas is down";
                  description = "Either the exporter or the postgres database itself is unreachable. Affected stack: nextcloud / paperless / immich / finance-buddy.";
                  severity = "critical";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_disk_near_full";
                  title = "Home NAS Root Disk Near Full";
                  expr = ''100 - ((node_filesystem_avail_bytes{job="home-nas-node",fstype!~"tmpfs|overlay|nsfs|squashfs",mountpoint="/"} / node_filesystem_size_bytes{job="home-nas-node",fstype!~"tmpfs|overlay|nsfs|squashfs",mountpoint="/"}) * 100)'';
                  thresholdType = "gt";
                  thresholdValue = 90;
                  forDuration = "15m";
                  summary = "Root filesystem >90% on a home-nas host";
                  description = "Less than 10% of the root filesystem is free on a home-nas host. Investigate before things start failing.";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_memory_pressure";
                  title = "Home NAS Memory Pressure";
                  expr = ''(1 - (node_memory_MemAvailable_bytes{job="home-nas-node"} / node_memory_MemTotal_bytes{job="home-nas-node"})) * 100'';
                  thresholdType = "gt";
                  thresholdValue = 92;
                  forDuration = "15m";
                  summary = "Memory utilisation >92% on a home-nas host";
                  description = "Sustained high memory pressure. OOM killer may start picking off containers soon.";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_traefik_5xx_high";
                  title = "Traefik 5xx Rate High";
                  expr = ''sum(rate(traefik_service_requests_total{code=~"5..",job="home-nas-traefik"}[5m])) / clamp_min(sum(rate(traefik_service_requests_total{job="home-nas-traefik"}[5m])), 1) * 100'';
                  thresholdType = "gt";
                  thresholdValue = 5;
                  forDuration = "10m";
                  summary = "Traefik 5xx rate above 5%";
                  description = "Reverse proxy is returning 5xx errors at >5% for 10+ minutes. Check upstream services routed via Traefik.";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_sybra_provider_unhealthy";
                  title = "Sybra Provider Unhealthy";
                  expr = ''min(sybra_provider_healthy{job="home-nas-sybra"})'';
                  thresholdType = "lt";
                  thresholdValue = 1;
                  forDuration = "10m";
                  summary = "Sybra LLM provider is unhealthy";
                  description = "One or more Sybra LLM providers have been reporting unhealthy for 10+ minutes. Agent runs may be failing or failing over.";
                  severity = "warning";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_sybra_auth_failures";
                  title = "Sybra Provider Auth Failures";
                  expr = ''sum(increase(sybra_provider_auth_failures_total{job="home-nas-sybra"}[10m]))'';
                  thresholdType = "gt";
                  thresholdValue = 3;
                  forDuration = "5m";
                  summary = "Sybra provider auth failures spiking";
                  description = "More than 3 provider auth failures in the last 10 minutes. API keys may be expired, rotated, or rejected.";
                  severity = "warning";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_sybra_agent_failovers";
                  title = "Sybra Agent Failover Churn";
                  expr = ''sum(increase(sybra_agent_failovers_total{job="home-nas-sybra"}[1h]))'';
                  thresholdType = "gt";
                  thresholdValue = 5;
                  forDuration = "5m";
                  summary = "Sybra agents failing over frequently";
                  description = "More than 5 agent failovers in the last hour. Primary provider or configuration may be unstable.";
                  severity = "warning";
                })
                (mkPromExprAlertRule {
                  uid = "home_nas_sybra_monitor_stale";
                  title = "Sybra Monitor Stale";
                  expr = ''max(sybra_monitor_heartbeat_age_seconds{job="home-nas-sybra"})'';
                  thresholdType = "gt";
                  thresholdValue = 600;
                  forDuration = "5m";
                  summary = "Sybra monitor heartbeat is stale";
                  description = "Sybra monitor heartbeat age has exceeded 10 minutes. Orchestrator loop may be stuck or crashed.";
                  severity = "warning";
                })
              ]
              ++ map mkInstanceDownRule perInstanceServices;
          }
        ];

        policies.settings.policies = [
          {
            receiver = "Home Assistant Telegram";
            group_by = ["alertname" "severity"];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
          }
        ];
      };
    };
  };

  # Grafana waits for sops-nix secrets via sops.secrets.<name>.restartUnits
  # (configured in sops section of main config)
}
