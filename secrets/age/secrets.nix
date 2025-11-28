let
  keys = import ../keys.nix;
  allHosts = [keys.hosts.nixos keys.hosts.router];
in {
  "sing-box-vless-uuid.age".publicKeys = allHosts;
  "sing-box-reality-pubkey.age".publicKeys = allHosts;
  "sing-box-reality-short-id.age".publicKeys = allHosts;
  "sing-box-vless-server.age".publicKeys = allHosts;
}
