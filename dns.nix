{...}: {
  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = 53;
        tls = 853;
        https = 443;
      };

      bootstrapDns = "tcp+udp:9.9.9.9";
      upstreams.groups = {
        default = [
          "https://dns.quad9.net/dns-query"
          "https://194.242.2.2" # Mullvad
        ];
      };

      caching = {
        maxItemsCount = 10000;
        maxTime = "1h";
        minTime = "5m";
        # cacheTimeNegative = "-1"; # Disables negative caching
        prefetching = true;
        prefetchMaxItemsCount = 10000;
        prefetchExpires = "2h";
        prefetchThreshold = 5;
      };

      customDNS.mapping = {
        "router.local" = "10.0.0.1";
      };

      blocking = {
        blockType = "zeroIP"; # Returns 0.0.0.0 or :: as result
        blockTTL = "1h";

        # Blocklists loading settings
        loading = {
          refreshPeriod = "24h";
          strategy = "fast";
          downloads = {
            attempts = 3;
            cooldown = "10s";
            timeout = "5m";
          };
        };

        denylists = {
          suspicious = [
            "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" # https://github.com/StevenBlack/hosts
            "https://v.firebog.net/hosts/static/w3kbl.txt"
          ];
          ads = [
            "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
            "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
            "https://v.firebog.net/hosts/AdguardDNS.txt"
            "https://v.firebog.net/hosts/Admiral.txt"
            "https://v.firebog.net/hosts/Easylist.txt"
          ];
          tracking = [
            "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
          ];
          malicious = [
            "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
            "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
            "https://phishing.army/download/phishing_army_blocklist_extended.txt"
            "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
            "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
            "https://urlhaus.abuse.ch/downloads/hostfile/"
            "https://v.firebog.net/hosts/Prigent-Crypto.txt"
            "https://v.firebog.net/hosts/Prigent-Malware.txt"
          ];
          other = [
            "https://big.oisd.nl/domainswild"
            "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
          ];
        };
        clientGroupsBlock = {
          default = [
            "ads"
            "malicious"
            "other"
            "suspicious"
            "tracking"
          ];
        };
      };

      # hostsFile.sources = ["/etc/hosts"];

      # TODO: Enable logging?
      queryLog.type = "console";

      prometheus.enable = true;

      log.level = "info";
    };
  };
}
