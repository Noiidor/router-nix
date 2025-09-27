{
  config,
  lib,
  ...
}: {
  options = {
    internal = lib.mkOption {type = lib.types.str;};
    wan = lib.mkOption {type = lib.types.str;};
    lan = lib.mkOption {type = lib.types.str;};
  };

  config = {
    internal = "10.0.0.1";
    wan = "enp2s0";
    lan = "lan-br";
  };
}
