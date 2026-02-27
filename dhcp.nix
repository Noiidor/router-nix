{config, ...}: {
  services.resolved.enable = false;
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [config.lan];
        service-sockets-max-retries = 10;
        service-sockets-retry-wait-time = 5000;
      };
      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;

      subnet4 = [
        {
          id = 1;
          subnet = "${config.internal}/24";
          pools = [{pool = "10.0.0.50 - 10.0.0.200";}];

          option-data = [
            # This announces router as a default gateway
            {
              name = "routers";
              data = config.internal;
            }
            # Announces available nameservers
            {
              name = "domain-name-servers";
              # data = "9.9.9.9, 1.1.1.1, 8.8.8.8";
              data = config.internal;
            }
          ];
        }
      ];

      expired-leases-processing = {
        hold-reclaimed-time = 360000;
      };

      lease-database = {
        name = "/var/lib/kea/kea-leases4.csv";
        type = "memfile";
        lfc-interval = 3600;
      };

      loggers = [
        {
          name = "*";
          severity = "DEBUG";
        }
      ];
    };
  };
}
