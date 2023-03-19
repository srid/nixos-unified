{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:srid/nixos-flake";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      imports = [ inputs.nixos-flake.flakeModule ];

      flake =
        let
          # TODO: Change username
          myUserName = "john";
        in
        {
          # Configurations for macOS machines
          # TODO: Change hostname from "example1" to something else.
          darwinConfigurations.example1 =
            self.nixos-flake.lib.mkARMMacosSystem {
              imports = [
                # Your machine's configuration.nix goes here
                ({ pkgs, ... }: {
                  security.pam.enableSudoTouchIdAuth = true;
                })
                # Your home-manager configuration
                self.darwinModules.home-manager
                {
                  home-manager.users.${myUserName} = {
                    imports = [ self.homeModules.default ];
                    home.stateVersion = "22.11";
                  };
                }
              ];
            };

          # home-manager configuration goes here.
          homeModules.default = { pkgs, ... }: {
            imports = [ ];
            programs.git.enable = true;
            programs.starship.enable = true;
          };
        };
    };
}
