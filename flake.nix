            {
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };
  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.router = nixpkgs.lib.nixosSystem {
      modules = [ ./configuration.nix ];
    };
  };
}

