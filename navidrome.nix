{...}: {
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/opt/navidrome/music";
      Address = "0.0.0.0";
    };
  };
}
