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
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        inputs.nixos-unified.flakeModules.default
      ];

      perSystem = { pkgs, ... }:
        let
          myUserName = "john";
        in
        {
          legacyPackages.homeConfigurations.${myUserName} =
            self.nixos-unified.lib.mkHomeConfiguration
              pkgs
              ({ pkgs, ... }: {
                imports = [ self.homeModules.default ];
                home.username = myUserName;
                home.stateVersion = "24.11";
              });
        };

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
