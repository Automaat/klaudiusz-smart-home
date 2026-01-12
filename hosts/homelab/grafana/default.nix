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
                  serviceName = "crowdsec_bouncer";
                  unitName = "crowdsec-firewall-bouncer.service";
                  title = "CrowdSec Firewall Bouncer Down";
                  summary = "CrowdSec firewall bouncer is not running";
                  description = "The crowdsec-firewall-bouncer.service has been inactive for more than 10 minutes. IP bans not enforced. Check: systemctl status crowdsec-firewall-bouncer";
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
              {
                uid = "crowdsec_no_parser_activity";
                title = "CrowdSec Not Processing Logs";
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
                      expr = ''rate(cs_parser_hits_total[5m])'';
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
                            params = [0.01];
                            type = "lt";
                          };
                        }
                      ];
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "10m";
                annotations = {
                  summary = "CrowdSec parser activity is near zero";
                  description = "CrowdSec has not processed any logs for more than 10 minutes. Check: systemctl status crowdsec && journalctl -u crowdsec -n 50";
                };
                labels = {
                  severity = "warning";
                  service = "crowdsec";
                };
                isPaused = false;
              }
            ];
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
