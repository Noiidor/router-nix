{
  lib,
  pkgs,
  config,
  ...
}: {
  # Upstream xray module is broken for TUN inbound
  disabledModules = ["services/networking/xray.nix"];
  imports = [
    ./modules/xray.nix
  ];
  services.xray = {
    enable = true;
    package = pkgs.unstable.xray;
    settings = {
      log = {
        logLevel = "debug";
        dnsLog = true;
      };
      dns = {
        servers = [
          "127.0.0.1"
          {
            address = "https://dns.quad9.net/dns-query";
          }
          "9.9.9.9"
          "1.1.1.1"
        ];
      };
      inbounds = [
        {
          protocol = "socks";
          tag = "socks-in";
          listen = "0.0.0.0";
          port = 10808;
          settings = {
            udp = true;
          };
          sniffing = {
            enabled = true;
            destOverride = ["http" "tls" "quic"];
            routeOnly = true;
          };
        }
        {
          protocol = "tun";
          tag = "tun-in";
          listen = "10.0.1.1/30";
          settings = {
            name = "xray0";
            MTU = 1500;
          };
        }
        {
          protocol = "http";
          tag = "http-in";
          listen = "0.0.0.0";
          port = 8118;
          settings = {
            users = [];
            allowTransparent = true;
          };
          sniffing = {
            enabled = true;
            destOverride = ["http" "tls" "quic"];
            routeOnly = true;
          };
        }
      ];
      outbounds = let
        vlessBase = idx: addrPath: sni: {
          tag = "vless-out-${toString idx}";
          protocol = "vless";
          settings = {
            address._secret = addrPath;
            port = 443;
            id._secret = config.age.secrets.xray-vless-uuid.path;
            encryption = "none";
            flow = "xtls-rprx-vision";
          };
          streamSettings = {
            network = "raw";
            security = "reality";
            realitySettings = {
              serverName = sni;
              password._secret = config.age.secrets.xray-reality-password.path;
              shortId._secret = config.age.secrets.xray-reality-short-id.path;
              fingerprint = "firefox";
              show = true;
            };
          };
        };
      in [
        (vlessBase 1 config.age.secrets.xray-vless-server.path "blocket.se")
        (vlessBase 2 config.age.secrets.xray-vless-server1.path "antenne.de")
        {
          tag = "direct-out";
          protocol = "freedom";
        }
        {
          tag = "block-out";
          protocol = "blackhole";
        }
      ];
      burstObservatory = {
        subjectSelector = ["vless-out-"];
        pingConfig = {
          destination = "https://connectivitycheck.gstatic.com/generate_204";
          sampling = 5;
          interval = "1m";
          timeout = "5s";
          httpMethod = "HEAD";
        };
      };
      routing = {
        balancers = [
          {
            tag = "vless-bl";
            selector = ["vless-out-"];
            fallbackTag = "direct-out";
            strategy = {
              type = "random";
            };
          }
        ];
        domainStrategy = "IPIfNonMatch";
        rules = [
          {
            type = "field";
            domain = ["*.ru"];
            outboundTag = "direct-out";
          }
          {
            type = "field";
            domain = ["router.local" "localhost"];
            outboundTag = "direct-out";
          }
          {
            type = "field";
            ip = ["geoip:private"];
            outboundTag = "direct-out";
          }
          {
            inboundTag = "socks-in";
            balancerTag = "vless-bl";
          }
        ];
      };
    };
  };
}
