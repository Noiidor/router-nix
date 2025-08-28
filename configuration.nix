{
  config,
  lib,
  pkgs,
  ...
}: let
  internal = "10.0.0.1";

  wan = "enp2s0";
  lan = "lan-br";
in {
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernel = {
      sysctl = {
        # Enables routing
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;

        # Discards Martian packets
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.${wan}.rp_filter" = 1;
        "net.ipv4.conf.${lan}.rp_filter" = 0;
      };
    };
  };
  # networking.

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  users.users.noi = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3vc5mJ3TAZy2q9P1ZkKkDquCMWw2EZPZpqfSlmZ4F3 noidor2019@gmail.com"
    ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    btop
    tmux
    rsync
    iperf3
  ];

  programs = {
    zsh.enable = true;
    git = {
      enable = true;
      config = {
        init.defaultBranch = "master";
        pull = {
          rebase = true;
        };
      };
    };
    nh = {
      enable = true;
      flake = "/home/noi/router-nix";
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  services.resolved.enable = false;

  networking = {
    hostName = "router";
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    useNetworkd = true;
    useDHCP = false;
    dhcpcd.enable = false;

    nat.enable = false;
    firewall.enable = false;

    # firewall.allowedTCPPorts = [
    #   22 # SSH
    # ];
    # firewall.allowedUDPPorts = [
    #   67 # DHCP
    #   68 # DHCP
    # ];
    #
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0; policy drop;

            iifname { "${lan}" } accept comment "Allow local network to access the router"
            iifname "${wan}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${wan}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "${wan}" counter drop comment "Drop all other unsolicited traffic from wan"
            iifname "lo" accept comment "Accept everything from loopback interface"
          }
          chain forward {
            type filter hook forward priority filter; policy drop;

            iifname { "${lan}" } oifname { "${wan}" } accept comment "Allow trusted LAN to WAN"
            iifname { "${wan}" } oifname { "${lan}" } ct state { established, related } accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "${wan}" masquerade
          }
        }
      '';
    };
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    netdevs = {
      "20-${lan}" = {
        netdevConfig = {
          Kind = "bridge";
          Name = lan;
        };
      };
    };
    networks = {
      "30-${lan}" = {
        matchConfig.Name = lan;
        bridgeConfig = {};
        linkConfig.RequiredForOnline = "carrier";
        address = [
          "${internal}/24"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          # DHCPServer = true;
          DHCPPrefixDelegation = true;
        };
        # dhcpServerConfig = {
        #   DNS = internal;
        #   NTP = internal
        #   EmitDNS = true;
        #   EmitNTP = true;
        #   EmitRouter = true;
        #   EmitTimezone = true;
        #   ServerAddress = "${internal}/24";
        #   UplinkInterface = "enp1s0";
        # };
        dhcpPrefixDelegationConfig = {
          Announce = true;
          SubnetId = 1;
          UplinkInterface = wan;
        };
      };

      "30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        linkConfig.RequiredForOnline = "enslaved";
        networkConfig = {
          Bridge = lan;
          ConfigureWithoutCarrier = true;
        };
      };

      "10-${wan}" = {
        matchConfig.Name = wan;
        linkConfig.RequiredForOnline = "carrier";
        networkConfig = {
          IPv4Forwarding = true;
          DHCP = "yes";
          DNSOverTLS = true;
          DNSSEC = true;
          # DHCPPrefixDelegation = true;
        };
        # dhcpV4Config = {
        #   UseDNS = false;
        #   UseRoutes = true;
        # };
        # dhcpPrefixDelegationConfig = {
        #   UplinkInterface = ":self";
        #   Announce = false;
        #   SubnetId = 0;
        # };
      };
    };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      server = ["8.8.8.8" "1.1.1.1" "8.8.4.4"];
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;

      cache-size = 1000;
      dhcp-range = ["${lan},10.0.0.50,10.0.0.200,24h"];
      interface = "${lan}";
      dhcp-host = internal;

      local = "/lan/";
      domain = "lan";
      expand-hosts = true;

      no-hosts = true;
      address = "/surfer.lan/${internal}";
    };
  };

  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  system.stateVersion = "25.05";
}
