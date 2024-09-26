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

    nixosModules = {
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

    darwinModules = {
      # macOS home-manager module
      home-manager = {
        imports = [
          inputs.home-manager.darwinModules.home-manager
          ({
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgsFor.darwin;
            home-manager.sharedModules = [{
              home.sessionPath = [
                "/etc/profiles/per-user/$USER/bin" # To access home-manager binaries
                "/nix/var/nix/profiles/system/sw/bin" # To access nix-darwin binaries
                "/usr/local/bin" # Some macOS GUI programs install here
              ];
            }];
          })
        ];
      };
      # nix-darwin module containing necessary configuration
      # Required when using the DetSys installer
      # cf. https://github.com/srid/nixos-flake/issues/52
      nix-darwin = {
        nix = {
          useDaemon = true; # Required on multi-user Nix install
          settings = {
            experimental-features = "nix-command flakes"; # Enable flakes
          };
        };
      };
    };
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
      nixos-flake.lib = rec {
        inherit specialArgsFor;

        mkLinuxSystem = { home-manager ? false }: mod: inputs.nixpkgs.lib.nixosSystem {
          # Arguments to pass to all modules.
          specialArgs = specialArgsFor.nixos;
          modules = [
            ./nixos-module.nix
            mod
          ] ++ lib.optional home-manager nixosModules.home-manager;
        };

        mkMacosSystem = { home-manager ? false }: mod: inputs.nix-darwin.lib.darwinSystem {
          specialArgs = specialArgsFor.darwin;
          modules = [
            ./nixos-module.nix
            darwinModules.nix-darwin
            mod
          ] ++ lib.optional home-manager darwinModules.home-manager;
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
