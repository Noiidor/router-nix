let
  keys = import ../keys.nix;
  allHosts = [keys.hosts.nixos keys.hosts.router];
in {
  "sing-box-vless-uuid.age".publicKeys = allHosts;
  "sing-box-reality-pubkey.age".publicKeys = allHosts;
  "sing-box-reality-short-id.age".publicKeys = allHosts;
  "sing-box-vless-server.age".publicKeys = allHosts;

  "xray-vless-server.age".publicKeys = allHosts;
  "xray-vless-server1.age".publicKeys = allHosts;
  "xray-vless-uuid.age".publicKeys = allHosts;
  "xray-reality-short-id.age".publicKeys = allHosts;
  "xray-reality-password.age".publicKeys = allHosts;

  "zigbee2mqtt-password.age".publicKeys = allHosts;
  "mosquitto-hashed-password.age".publicKeys = allHosts;
}
