{
  config,
  lib,
  pkgs,
  utils,
  ...
}: {
  options = {
    services.xray = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to run xray server.
          Either `settingsFile` or `settings` must be specified.
        '';
      };

      package = lib.mkPackageOption pkgs "xray" {};

      runtimeDir = lib.mkOption {
        type = lib.types.str;
        default = "/run/xray";
        description = ''
          The directory where the runtime config.json will be generated.
        '';
      };

      settingsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/etc/xray/config.json";
        description = ''
          The absolute path to the configuration file.
          Either `settingsFile` or `settings` must be specified.
          See <https://xtls.github.io/en/config/>.
        '';
      };

      settings = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.unspecified);
        default = null;
        example = {
          inbounds = [
            {
              port = 1080;
              listen = "127.0.0.1";
              protocol = "http";
            }
          ];
          outbounds = [
            {
              protocol = "freedom";
            }
          ];
        };
        description = ''
          The configuration object.
          Either `settingsFile` or `settings` must be specified.
          See <https://xtls.github.io/en/config/>.

          Options containing secret data should be set to an attribute set
          containing the attribute `_secret` - a string pointing to a file
          containing the value the option should be set to.
        '';
      };
    };
  };

  config = let
    cfg = config.services.xray;
    settingsFile =
      if cfg.settingsFile != null
      then cfg.settingsFile
      else
        pkgs.writeTextFile {
          name = "xray-placeholder.json";
          text = builtins.toJSON cfg.settings;
        };

    preStartScript = pkgs.writeShellScript "xray-pre-start" ''
      mkdir -p ${cfg.runtimeDir}
      ${utils.genJqSecretsReplacementSnippet cfg.settings "${cfg.runtimeDir}/config.json"}
      chown --reference=${cfg.runtimeDir} ${cfg.runtimeDir}/config.json
    '';

    runtimeConfigPath = "${cfg.runtimeDir}/config.json";
  in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = (cfg.settingsFile == null) != (cfg.settings == null);
          message = "Either but not both `settingsFile` and `settings` should be specified for xray.";
        }
      ];

      systemd.services.xray = {
        description = "xray Daemon";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        script = ''
          exec "${lib.getExe cfg.package}" -config ${runtimeConfigPath}
        '';
        serviceConfig = {
          DynamicUser = true;
          ExecStartPre = "+${preStartScript}";
          LoadCredential = "config.json:${settingsFile}";
          RuntimeDirectory = "xray";
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          DeviceAllow = "/dev/net/tun rw";
          NoNewPrivileges = true;
        };
      };
    };
}

