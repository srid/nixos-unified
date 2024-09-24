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
  hasNonEmptyAttr = attrPath: self:
    lib.attrByPath attrPath { } self != { };
in
{
  options = {
    perSystem =
      mkPerSystemOption ({ config, self', inputs', pkgs, system, ... }: {
        options.nixos-flake = lib.mkOption {
          default = { };
          type = types.submodule {
            options = {
              primary-inputs = lib.mkOption {
                type = types.listOf types.str;
                default = [ "nixpkgs" "home-manager" "nix-darwin" ];
                description = ''
                  List of flake inputs to update when running `nix run .#update`.
                '';
              };
            };
          };
        };
        config = {
          packages = lib.filterAttrs (_: v: v != null) {
            update =
              let
                inputs = config.nixos-flake.primary-inputs;
              in
              pkgs.writeShellApplication {
                name = "update-main-flake-inputs";
                meta.description = "Update the primary flake inputs";
                text = ''
                  nix flake lock ${lib.foldl' (acc: x: acc + " --update-input " + x) "" inputs}
                '';
              };

            # Activate the given (system or home) configuration
            activate = import ../activate { inherit self inputs' pkgs lib system; };
          };
        };
      });
  };

  config = {
    flake = {
      nixosModules = {
        nixosFlake = ./nixos-module.nix;
        # Linux home-manager module
        home-manager = {
          imports = [
            inputs.home-manager.nixosModules.home-manager
            ({
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgsFor.nixos;
            })
          ];
        };
      };

      darwinModules_ = {
        nixosFlake = ./nixos-module.nix;
        # macOS home-manager module
        # This is named with an underscope, because flake-parts segfaults otherwise!
        # See https://github.com/srid/nixos-config/issues/31
        home-manager = {
          imports = [
            inputs.home-manager.darwinModules.home-manager
            ({
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgsFor.darwin;
            })
          ];
        };
      };

      nixos-flake.lib = rec {
        inherit specialArgsFor;

        mkLinuxSystem = mod: inputs.nixpkgs.lib.nixosSystem {
          # Arguments to pass to all modules.
          specialArgs = specialArgsFor.nixos;
          modules = [
            self.nixosModules.nixosFlake
            mod
          ];
        };

        mkMacosSystem = mod: inputs.nix-darwin.lib.darwinSystem {
          specialArgs = specialArgsFor.darwin;
          modules = [
            self.darwinModules_.nixosFlake
            mod
          ];
        };

        mkHomeConfiguration = pkgs: mod: inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = specialArgsFor.common;
          modules = [ mod ];
        };
      };
    };
  };
}
