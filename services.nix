{
  config,
  pkgs,
  ...
}: {
  services = {
    taskchampion-sync-server = {
      enable = true;
      host = "0.0.0.0";
      snapshot = {
        days = 2;
        versions = 50;
      };
    };
  };
}
