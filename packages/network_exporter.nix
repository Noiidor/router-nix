{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "network_exporter";
  version = "1.7.10";

  src = fetchFromGitHub {
    owner = "syepes";
    repo = "network_exporter";
    tag = version;
    hash = "sha256-U8Fnb3jONUNW77LZ2JmzAiHpngGP9LlTcbMtNzEKb34=";
  };

  vendorHash = "sha256-cMD0D+4/rEQ9o/kY7FgcQroo0R84UuKhynCrv85pD1w=";

  meta = {
    description = "ICMP / Ping & MTR & TCP Port & HTTP Get - Network Prometheus exporter";
    homepage = "https://github.com/syepes/network_exporter";
    license = lib.licenses.asl20;
  };
}
