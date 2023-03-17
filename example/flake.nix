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
          # Common home-manager configuration shared between Linux and macOS.
          homeConfigurations.common = { pkgs, ... }: {
            programs.git.enable = true;
            programs.starship.enable = true;
          };

          # Configurations for Linux (NixOS) systems
          nixosConfigurations = {
            # TODO: Change hostname from "example1" to something else.
            example1 = self.lib.mkLinuxSystem {
              imports = [
                # Your configuration.nix goes here
                ({ pkgs, ... }: {
                  # TODO: Use your real hardware configuration here
                  boot.loader.grub.device = "nodev";
                  fileSystems."/" = {
                    device = "/dev/disk/by-label/nixos";
                    fsType = "btrfs";
                  };
                  users.users.${myUserName}.isNormalUser = true;
                  environment.systemPackages = with pkgs; [
                    hello
                  ];
                })
                # Your home-manager configuration
                self.nixosModules.home-manager
                {
                  home-manager.users.${myUserName} = {
                    imports = [
                      self.homeConfigurations.common
                    ];
                    home.stateVersion = "22.11";
                  };
                }
              ];
            };
          };

          # Configurations for a single macOS machine (using nix-darwin)
          darwinConfigurations = {
            # TODO: Change hostname from "example1" to something else.
            example1 = self.lib.mkARMMacosSystem {
              imports = [
                # Your configuration.nix goes here
                ({ pkgs, ... }: {
                  environment.systemPackages = with pkgs; [
                    hello
                  ];
                })
                # Your home-manager configuration
                self.darwinModules.home-manager
                {
                  home-manager.users.${myUserName} = {
                    imports = [
                      self.homeConfigurations.common
                    ];
                    home.stateVersion = "22.11";
                  };
                }
              ];
            };
          };
        };

      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
        formatter = pkgs.nixpkgs-fmt;
      };
    };
}
