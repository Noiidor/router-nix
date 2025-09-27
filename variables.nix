{
  config,
  lib,
  ...
}: {
  options = {
    internal = lib.mkOption {type = lib.types.str;};
    wan = lib.mkOption {type = lib.types.str;};
    lan = lib.mkOption {type = lib.types.str;};

    blockyApiPort = lib.mkOption {type = lib.types.port;};
  };

  config = {
    internal = "10.0.0.1";
    wan = "enp2s0";
    lan = "lan-br";

    blockyApiPort = 4000;
  };
}
