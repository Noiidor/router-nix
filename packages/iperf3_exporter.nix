{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "iperf3_exporter";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "edgard";
    repo = "iperf3_exporter";
    tag = version;
    hash = "sha256-A2zqv1CWDuIAuEGm4LnjZ0notnQtJltGlAQd9ce6DZQ=";
  };

  vendorHash = "sha256-tA0lx6xOVLw5uZzxYXkAE6IpaW4WjaB25w/AsH4piw8=";

  meta = {
    description = "Simple server that probes iPerf3 endpoints and exports results via HTTP for Prometheus consumption ";
    homepage = "https://github.com/edgard/iperf3_exporter";
    license = lib.licenses.asl20;
  };
}
