{
  config,
  pkgs,
  ...
}: let
  networkExporter = pkgs.callPackage ./packages/network_exporter.nix {};
  networkExporterPort = 9428;

  # TODO: Rewrire as a module
  # Packages a Go iperf3_exporter utility
  iPerf3Exporter = pkgs.callPackage ./packages/iperf3_exporter.nix {};
  iPerf3ExporterPort = 9579;
in {
  environment.systemPackages = [
    networkExporter
    iPerf3Exporter

    # (pkgs.callPackage ./packages/iperf3_exporter.nix {})
    # (pkgs.callPackage ./packages/network_exporter.nix {})
  ];

  # Prometheus
  services.prometheus = {
    enable = true;

    globalConfig = {
      scrape_interval = "30s";
    };

    # Exporters scrape configs
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
        job_name = "iperf3_exporter";
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
      {
        job_name = "network_exporter";
        scrape_timeout = "20s";
        static_configs = [
          {
            targets = ["localhost:${toString networkExporterPort}"];
          }
        ];
      }
    ];
  };

  # Exporters
  # Exporters systemd services
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

  systemd.services.network-exporter = {
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    description = "Network exporter for Prometheus";
    path = [];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${networkExporter}/bin/network_exporter --config.file=/etc/network_exporter/network_exporter.yml --web.listen-address=:${toString networkExporterPort} --log.level=debug";
    };
  };

  environment.etc."network_exporter/network_exporter.yml".source = ./configs/network_exporter.yml;

  # Exporters modules
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = ["systemd"];
    };
  };

  # Grafana
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

      dashboards.settings.providers = [
        {
          disableDeletion = true;
          name = "Declarative Dashboards";
          options = {
            path = "/etc/grafana-dashboards";
            foldersFromFilesStructure = true;
          };
        }
      ];

      datasources.settings.datasources = [
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

  environment.etc."grafana-dashboards/node-exporter-full.json".source = ./dashboards/node-exporter-full.json;
  environment.etc."grafana-dashboards/network-exporters.json".source = ./dashboards/network-exporters.json;
}
