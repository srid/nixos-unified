{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-unified.url = "github:srid/nixos-unified";
  };

  outputs = inputs@{ self, ... }:
    let
      specialArgs = { myUserName = "john"; };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs specialArgs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        inputs.nixos-unified.flakeModules.default
        ({ myUserName, ... }: {
          perSystem = { pkgs, ... }:
            {
              legacyPackages.homeConfigurations.${myUserName} =
                self.nixos-unified.lib.mkHomeConfiguration
                  pkgs
                  ({ pkgs, flake, ... }:
                    let
                      inherit (flake) myUserName;
                    in
                    {
                      imports = [ self.homeModules.default ];
                      home.username = myUserName;
                      home.homeDirectory = "/${if pkgs.stdenv.isDarwin then "Users" else "home"}/${myUserName}";
                      home.stateVersion = "22.11";
                    });
            };
        })
      ];

      flake = {
        # All home-manager configurations are kept here.
        homeModules.default = { pkgs, ... }: {
          imports = [ ];
          programs = {
            git.enable = true;
            starship.enable = true;
            bash.enable = true;
          };
        };
      };
    };
}
