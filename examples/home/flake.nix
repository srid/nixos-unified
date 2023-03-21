{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:srid/nixos-flake";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        inputs.nixos-flake.flakeModule
      ];

      flake =
        let
          # TODO: Change username
          myUserName = "john";
        in
        {
          homeConfigurations.${myUserName} =
            self.nixos-flake.lib.mkHomeConfiguration
              "x86_64-linux"  # FIXME: how to not hardcode this?
              ({ pkgs, ... }: {
                imports = [ self.homeModules.default ];
                home.username = myUserName;
                home.homeDirectory = "/${if pkgs.stdenv.isDarwin then "Users" else "home"}/${myUserName}";
                home.stateVersion = "22.11";
              });

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
