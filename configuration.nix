{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./variables.nix
    ./dns.nix
    ./dhcp.nix
    ./telemetry.nix
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
        "net.ipv4.conf.${config.wan}.rp_filter" = 1;
        "net.ipv4.conf.${config.lan}.rp_filter" = 0;
      };
    };
  };

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

  services = {
    openssh = {
      enable = true;
      allowSFTP = false;
      ports = [22];
      settings = {
        LogLevel = "VERBOSE";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1d";
      bantime-increment.enable = true;
    };
  };

  networking = {
    hostName = "router";
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    useNetworkd = true;

    # Using custom DHCP
    useDHCP = false;
    dhcpcd.enable = false;

    # Disables default firewall
    nat.enable = false;
    firewall.enable = false;

    nameservers = ["127.0.0.1" "::1"];

    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0; policy drop;

            iifname { "${config.lan}" } accept comment "Allow local network to access the router"
            iifname "${config.wan}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${config.wan}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "${config.wan}" counter drop comment "Drop all other unsolicited traffic from wan"
            iifname "lo" accept comment "Accept everything from loopback interface"
          }
          chain forward {
            type filter hook forward priority filter; policy drop;

            iifname { "${config.lan}" } oifname { "${config.wan}" } accept comment "Allow trusted LAN to WAN"
            iifname { "${config.wan}" } oifname { "${config.lan}" } ct state { established, related } accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "${config.wan}" masquerade
          }
        }
      '';
    };
  };

  # Using systemd-networkd as a network backend
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    netdevs = {
      "20-${config.lan}" = {
        netdevConfig = {
          Kind = "bridge";
          Name = config.lan;
        };
      };
    };
    networks = {
      "30-${config.lan}" = {
        matchConfig.Name = config.lan;
        bridgeConfig = {};
        linkConfig.RequiredForOnline = "carrier";
        address = [
          "${config.internal}/24"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
        };
        dhcpPrefixDelegationConfig = {
          Announce = true;
          SubnetId = 1;
          UplinkInterface = config.wan;
        };
      };

      "30-enp1s0" = {
        matchConfig.Name = "enp1s0";
        linkConfig.RequiredForOnline = "enslaved";
        networkConfig = {
          Bridge = config.lan;
          ConfigureWithoutCarrier = true;
        };
      };

      "10-${config.wan}" = {
        matchConfig.Name = config.wan;
        linkConfig.RequiredForOnline = "routable";
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

  # DHCP Server
  # For debugging
  # systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  system.stateVersion = "25.05";
}
