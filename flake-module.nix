{ self, inputs, config, flake-parts-lib, lib, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    types;
  specialArgsFor = rec {
    common = {
      flake = { inherit self inputs config; };
    };
    nixos = common;
    darwin = common // {
      rosettaPkgs = import inputs.nixpkgs { system = "x86_64-darwin"; };
    };
  };
in
{
  options = {
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }: {
        options.nixos-flake = lib.mkOption {
          default = { };
          type = types.submodule {
            options = {
              primary-inputs = lib.mkOption {
                type = types.listOf types.str;
                default = [ "nixpkgs" "home-manager" "darwin" ];
                description = ''
                  List of flake inputs to update when running `nix run .#update`.
                '';
              };
            };
          };
        };
        config = {
          packages = {
            update =
              let
                inputs = config.nixos-flake.primary-inputs;
              in
              pkgs.writeShellApplication {
                name = "update-main-flake-inputs";
                text = ''
                  nix flake lock ${lib.foldl' (acc: x: acc + " --update-input " + x) "" inputs}
                '';
              };

            activate =
              pkgs.writeShellApplication {
                name = "activate";
                text = ''
                  HOSTNAME=$(hostname -s)
                  set -x
                  ${self.nixos-flake.lib.system-rebuild pkgs system} switch --flake .#"''${HOSTNAME}" "$@"
                '';
              };
          };
        };
      });
  };

  config = {
    flake = {
      # Linux home-manager module
      nixosModules.home-manager = {
        imports = [
          inputs.home-manager.nixosModules.home-manager
          ({
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgsFor.nixos;
          })
        ];
      };
      # macOS home-manager module
      darwinModules.home-manager = {
        imports = [
          inputs.home-manager.darwinModules.home-manager
          ({
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgsFor.darwin;
          })
        ];
      };
      nixos-flake.lib = rec {
        mkLinuxSystem = mod: inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # Arguments to pass to all modules.
          specialArgs = specialArgsFor.nixos;
          modules = [ mod ];
        };

        mkMacosSystem = system: mod: inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = specialArgsFor.darwin;
          modules = [ mod ];
        };

        mkARMMacosSystem = mkMacosSystem "aarch64-darwin";
        mkIntelMacosSystem = mkMacosSystem "x86_64-darwin";

        # Like nixos-rebuild, but also works on macOS.
        system-rebuild = pkgs: system:
          if system == "aarch64-darwin" || system == "x86_64-darwin" then
            let
              # This is used just to pull out the `darwin-rebuild` script.
              emptyConfiguration = self.nixos-flake.lib.mkMacosSystem system { };
            in
            "${emptyConfiguration.system}/sw/bin/darwin-rebuild"
          else
            "${lib.getExe pkgs.nixos-rebuild}";
      };
    };
  };
}
