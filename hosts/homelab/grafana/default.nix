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
            rules = [
              # Critical services - immediate alert on failure
              {
                uid = "home_assistant_down";
                title = "Home Assistant Service Down";
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
                      expr = ''node_systemd_unit_state{name="home-assistant.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "Home Assistant service is not running";
                  description = "The home-assistant.service has been inactive for more than 2 minutes. Check: systemctl status home-assistant";
                };
                labels = {
                  severity = "critical";
                  service = "home-assistant";
                };
                isPaused = false;
              }
              {
                uid = "postgresql_down";
                title = "PostgreSQL Service Down";
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
                      expr = ''node_systemd_unit_state{name="postgresql.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "PostgreSQL service is not running";
                  description = "The postgresql.service has been inactive for more than 2 minutes. Check: systemctl status postgresql";
                };
                labels = {
                  severity = "critical";
                  service = "postgresql";
                };
                isPaused = false;
              }
              {
                uid = "whisper_down";
                title = "Whisper STT Service Down";
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
                      expr = ''node_systemd_unit_state{name="wyoming-faster-whisper-default.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "Whisper STT service is not running";
                  description = "The wyoming-faster-whisper-default.service has been inactive for more than 2 minutes. Voice commands will not work. Check: systemctl status wyoming-faster-whisper-default";
                };
                labels = {
                  severity = "warning";
                  service = "whisper";
                };
                isPaused = false;
              }
              {
                uid = "piper_down";
                title = "Piper TTS Service Down";
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
                      expr = ''node_systemd_unit_state{name="wyoming-piper-default.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "Piper TTS service is not running";
                  description = "The wyoming-piper-default.service has been inactive for more than 2 minutes. Voice responses will not work. Check: systemctl status wyoming-piper-default";
                };
                labels = {
                  severity = "warning";
                  service = "piper";
                };
                isPaused = false;
              }
              {
                uid = "tailscale_down";
                title = "Tailscale Service Down";
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
                      expr = ''node_systemd_unit_state{name="tailscaled.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "Tailscale service is not running";
                  description = "The tailscaled.service has been inactive for more than 2 minutes. Remote access via Tailscale will not work. Check: systemctl status tailscaled";
                };
                labels = {
                  severity = "warning";
                  service = "tailscale";
                };
                isPaused = false;
              }
              {
                uid = "grafana_down";
                title = "Grafana Service Down";
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
                      expr = ''node_systemd_unit_state{name="grafana.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "Grafana service is not running";
                  description = "The grafana.service has been inactive for more than 2 minutes. Dashboards and monitoring UI unavailable. Check: systemctl status grafana";
                };
                labels = {
                  severity = "warning";
                  service = "grafana";
                };
                isPaused = false;
              }
              {
                uid = "influxdb_down";
                title = "InfluxDB Service Down";
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
                      expr = ''node_systemd_unit_state{name="influxdb2.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "InfluxDB service is not running";
                  description = "The influxdb2.service has been inactive for more than 2 minutes. Time-series data collection stopped. Check: systemctl status influxdb2";
                };
                labels = {
                  severity = "warning";
                  service = "influxdb";
                };
                isPaused = false;
              }
              {
                uid = "prometheus_down";
                title = "Prometheus Service Down";
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
                      expr = ''node_systemd_unit_state{name="prometheus.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "Prometheus service is not running";
                  description = "The prometheus.service has been inactive for more than 2 minutes. Metrics collection and alerting stopped. Check: systemctl status prometheus";
                };
                labels = {
                  severity = "critical";
                  service = "prometheus";
                };
                isPaused = false;
              }
              {
                uid = "fail2ban_down";
                title = "fail2ban Service Down";
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
                      expr = ''node_systemd_unit_state{name="fail2ban.service",state="active"}'';
                      instant = true;
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      refId = "A";
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
                      conditions = [
                        {
                          evaluator = {
                            params = [1];
                            type = "lt";
                          };
                          operator = {type = "and";};
                          query = {params = ["A"];};
                          type = "query";
                        }
                      ];
                      datasource = {
                        type = "__expr__";
                        uid = "-100";
                      };
                      expression = "A";
                      intervalMs = 1000;
                      maxDataPoints = 43200;
                      reducer = "last";
                      refId = "C";
                      type = "reduce";
                    };
                  }
                ];
                noDataState = "Alerting";
                execErrState = "Alerting";
                for = "2m";
                annotations = {
                  summary = "fail2ban service is not running";
                  description = "The fail2ban.service has been inactive for more than 2 minutes. SSH brute-force protection disabled. Check: systemctl status fail2ban";
                };
                labels = {
                  severity = "warning";
                  service = "fail2ban";
                };
                isPaused = false;
              }
            ];
          }
        ];

        policies.settings.policies = [
          {
            orgId = 1;
            receiver = "Home Assistant Telegram";
            group_by = ["alertname" "severity"];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
            matchers = ["severity =~ \"warning|critical\""];
          }
        ];
      };
    };
  };

  # Grafana waits for sops-nix secrets via sops.secrets.<name>.restartUnits
  # (configured in sops section of main config)
}
