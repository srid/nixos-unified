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
      systems = [ "x86_64-linux" ];
      imports = [ inputs.nixos-flake.flakeModule ];

      flake =
        let
          # TODO: Change username
          myUserName = "john";
        in
        {
          # Configurations for Linux (NixOS) machines
          # TODO: Change hostname from "example1" to something else.
          nixosConfigurations.example1 = self.nixos-flake.lib.mkLinuxSystem {
            imports = [
              # Your machine's configuration.nix goes here
              ({ pkgs, ... }: {
                # TODO: Put your /etc/nixos/hardware-configuration.nix here
                boot.loader.grub.device = "nodev";
                fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "btrfs"; };
                users.users.${myUserName}.isNormalUser = true;
                system.stateVersion = "23.05";
              })
              # Setup home-manager in NixOS config
              self.nixosModules.home-manager
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
            programs.bash.enable = true;
          };
        };
    };
}
