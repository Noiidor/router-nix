{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sing-box
  ];
  # Sing-box client for all local network
  services.sing-box = {
    enable = true;
    package = pkgs.unstable.sing-box;
    settings = {
      log = {
        level = "debug";
      };
      dns = {
        final = "dns-local";
        servers = [
          {
            type = "local";
            tag = "dns-local";

            # server = "127.0.0.1";
          }
        ];
        # rules = [
        #   {
        #     server = "dns-local";
        #     action = "route";
        #     outbound = "direct-out";
        #   }
        # ];
        disable_cache = true;
      };
      route = {
        final = "vless-out"; # Send trafic directly by default
        auto_detect_interface = true;
        find_process = true;

        default_domain_resolver = {
          server = "dns-local";
        };

        rules = [
          {
            action = "sniff";
            # inbound = ["tun-in" "mixed-in"];
          }
          {
            # Direct local trafic
            ip_is_private = true;
            action = "route";
            outbound = "direct-out";
          }
          # {
          #   protocol = "dns";
          #   action = "hijack-dns";
          # }
          {
            # Proxy only blocked resources
            rule_set = [
              "geoip-ru-blocked"
              "geosite-ru-blocked"
              "geoip-ru-itdog-blocked"
            ];
            action = "route";
            outbound = "vless-out";
          }
          {
            protocol = "bittorrent";
            action = "route";
            outbound = "direct-out";
          }
          # {
          #   network = "udp";
          #   source_port = [53];
          #   action = "route";
          #   outbound = "direct-out";
          # }
        ];

        rule_set = [
          # {
          #   tag = "geoip-ru";
          #   type = "remote";
          #   format = "binary";
          #   download_detour = "vless-out";
          #   url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs";
          # }
          {
            tag = "geoip-ru-blocked";
            type = "remote";
            format = "binary";
            download_detour = "vless-out";
            url = "https://testingcf.jsdelivr.net/gh/runetfreedom/russia-v2ray-rules-dat@release/sing-box/rule-set-geoip/geoip-ru-blocked.srs";
          }
          {
            tag = "geosite-ru-blocked";
            type = "remote";
            format = "binary";
            download_detour = "vless-out";
            url = "https://testingcf.jsdelivr.net/gh/runetfreedom/russia-v2ray-rules-dat@release/sing-box/rule-set-geosite/geosite-ru-blocked.srs";
          }
          {
            tag = "geoip-ru-itdog-blocked";
            type = "remote";
            format = "binary";
            download_detour = "vless-out";
            url = "https://github.com/itdoginfo/allow-domains/releases/latest/download/russia_inside.srs";
          }
        ];
      };
      outbounds = [
        {
          type = "vless";
          tag = "vless-out";
          uuid._secret = config.age.secrets.sing-box-vless-uuid.path;
          flow = "xtls-rprx-vision";
          server._secret = config.age.secrets.sing-box-vless-server.path;
          server_port = 443;
          tls = {
            enabled = true;
            alpn = [
              "h2"
            ];
            server_name = "twitch.tv";
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
            reality = {
              enabled = true;
              public_key._secret = config.age.secrets.sing-box-reality-pubkey.path;
              short_id._secret = config.age.secrets.sing-box-reality-short-id.path;
            };
          };
        }
        {
          type = "direct";
          tag = "direct-out";
        }
      ];
      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          interface_name = "sing-box-tun";
          address = [
            "172.19.0.1/30"
            # TODO: Add IPv6
            # "fdfe:dcba:9876::1/126"
          ];
          route_exclude_address = [
            "127.0.0.0/8"
            "10.0.0.0/8"
            "9.9.9.9/32"

            "46.226.122.0/24"
            "91.212.64.0/24"
            "91.223.93.0/24"
            "185.73.192.0/22"
            "195.34.20.0/23"
          ];
          auto_route = true;
          auto_redirect = true;
          strict_route = true;
          mtu = 1500;
        }
        {
          tag = "socks-in";
          type = "socks";
          listen = "0.0.0.0";
          listen_port = 3080;
        }
        {
          tag = "http-in";
          type = "http";
          listen = "0.0.0.0";
          listen_port = 2080;
        }
      ];
      certificate = {
        store = "system";
      };
      experimental = {
        cache_file.enabled = true;
      };
    };
  };

  users.groups.sing-box = {};
  users.users.sing-box = {
    isSystemUser = true;
    group = "sing-box";
    extraGroups = ["acme"];
  };
}
