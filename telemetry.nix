{
  config,
  pkgs,
  ...
}: let
  # Packages a Go iperf3_exporter utility
  iPerf3Exporter = pkgs.callPackage ./packages/iperf3_exporter.nix {};
  iPerf3ExporterPort = 9579;
in {
  environment.systemPackages = [
    iPerf3Exporter
  ];

  services.prometheus = {
    enable = true;

    globalConfig = {
      scrape_interval = "30s";
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "iPerf3 exporter";
        scrape_timeout = "20s";
        metrics_path = "/probe";
        static_configs = [
          {
            targets = ["localhost:${toString iPerf3ExporterPort}"];
          }
        ];
        params = {
          target = ["ping.online.net"];
          port = ["5202"];
        };
      }
    ];
  };

  systemd.services.iperf3-exporter = {
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    description = "iPerf3 exporter for Prometheus";
    path = [pkgs.iperf3];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${iPerf3Exporter}/bin/iperf3_exporter --web.listen-address=:${toString iPerf3ExporterPort}";
    };
  };

  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = ["systemd"];
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        enable_gzip = true;
      };
    };

    provision = {
      enable = true;

      dashboards = {
        settings = {
          providers = [
            {
              name = "Node Exporter Full";
              options.path = "/etc/grafana-dashboards";
            }
          ];
        };
      };

      datasources = {
        settings = {
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
              isDefault = true;
              editable = false;
            }
          ];
        };
      };
    };
  };

  environment.etc."grafana-dashboards/node-exporter-full.json".source = ./dashboards/node-exporter-full.json;
}
