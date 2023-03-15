{
  inputs = {
    # Principle inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixos-flake.url = "github:srid/nixos-flake";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      imports = [
        inputs.nixos-flake.flakeModule
      ];

      flake = {
        # Configurations for Linux (NixOS) systems
        nixosConfigurations = {
          # TODO: Change hostname fromm "example1" to something else.
          example1 = self.lib.mkLinuxSystem {
            imports = [
              self.nixosModules.home-manager
              # Your configuration.nix goes here
              ({ pkgs, ... }: {
                # TODO: Use your real hardware configuration here
                boot.loader.grub.device = "nodev";
                fileSystems."/" = {
                  device = "/dev/disk/by-label/nixos";
                  fsType = "btrfs";
                };
                environment.systemPackages = with pkgs; [
                  hello
                ];
              })
            ];
          };
        };

        # Configurations for my (only) macOS machine (using nix-darwin)
        darwinConfigurations = {
          default = self.lib.mkMacosSystem {
            imports = [
              self.darwinModules.home-manager
              # Your configuration.nix goes here
              ({ pkgs, ... }: {
                environment.systemPackages = with pkgs; [
                  hello
                ];
              })
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
