{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation = {
    podman.enable = true;
    oci-containers = {
      backend = "podman";
      containers.home-assistant = {
        volumes = ["ha-config-volume:/config"];
        environment = {
          TZ = "Europe/Moscow";
        };
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [
          "--network=host"
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"
          # "--pull=always"
        ];
      };
    };
  };
  services = {
    mosquitto = {
      enable = true;
      logType = ["all"];
      listeners = [
        {
          users.ha = {
            acl = [
              "readwrite #"
            ];
            hashedPasswordFile = config.age.secrets.mosquitto-hashed-password.path;
          };
        }
      ];
    };
    zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant.enabled = true;
        frontend = {
          enabled = true;
          package = "zigbee2mqtt-windfront";
          url = "http://zigbee2mqtt.local";
          host = "0.0.0.0";
        };
        mqtt = {
          server = "mqtt://127.0.0.1:1883";
          user = "ha";
          password = "!/run/secrets/zigbee2mqtt.yaml password";
        };
        serial = {
          port = "/dev/ttyUSB0";
          adapter = "zstack";
        };
      };
    };
  };

  system.activationScripts. zigbee2mqtt-secret = lib.stringAfter ["users"] ''
    set -euo pipefail
    umask 077

    secret_path="${config.age.secrets.zigbee2mqtt-password.path}"
    out="/run/secrets/zigbee2mqtt.yaml"
    tmp="$(mktemp -p /run tmp.activationScript.XXXXXX)"


    if [ ! -r "$secret_path" ]; then
      echo "WARN: secret file not found or not accesible: $secret_path" >&2
      exit 0
    fi

    content=$(cat ${config.age.secrets.zigbee2mqtt-password.path}) ${lib.getExe pkgs.yq-go} e -n '.password = strenv(content)' > "$tmp"

    install -m 600 -o zigbee2mqtt -g zigbee2mqtt -D "$tmp" "$out"
    rm -f "$tmp"
  '';
}
