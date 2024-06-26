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
    perSystem = mkPerSystemOption ({ config, self', inputs', pkgs, system, ... }:
      {
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
                text = ''
                  nix flake lock ${lib.foldl' (acc: x: acc + " --update-input " + x) "" inputs}
                '';
              };

            # New-style activate app that can also activately remotely over SSH.
            activate =
              let
                mkActivateApp = { flake }:
                  let
                    # Workaround https://github.com/NixOS/nix/issues/8752
                    cleanFlake = lib.cleanSourceWith {
                      name = "nixos-flake-activate-flake";
                      src = flake;
                    };
                    nixos-flake-configs = lib.mapAttrs (name: value: value.config.nixos-flake) (self.nixosConfigurations or { } // self.darwinConfigurations or { });
                    data = {
                      nixos-flake-configs = nixos-flake-configs;
                      system = system;
                      cleanFlake = cleanFlake;
                    };
                    dataFile = pkgs.writeTextFile {
                      name = "nixos-flake-activate-data";
                      text = ''
                        ${builtins.toJSON data}
                      '';
                    };
                    nixosFlakeNuModule = pkgs.writeTextFile {
                      name = "nixos-flake.nu";
                      text = ''
                        export def getData [] {
                          open ${dataFile} | from json
                        }
                      '';
                    };
                    runtimeInputs =
                      # TODO: better way to check for nix-darwin availability
                      if pkgs.stdenv.isDarwin && lib.hasAttr "nix-darwin" inputs' then [
                        inputs'.nix-darwin.packages.default # Provides darwin-rebuild
                      ] else [
                        pkgs.nixos-rebuild
                      ];
                    nixNuModule = pkgs.writeTextFile {
                      name = "nix.nu";
                      text = ''
                        export def useRuntimeInputs [] {
                          use std *
                          let bins = '${builtins.toJSON (builtins.map (p: lib.getBin p) runtimeInputs)}' | from json
                          if $bins != [] {
                            path add ...$bins
                          }
                        }
                      '';
                    };
                    nuPackage = pkgs.runCommandNoCC "nushell"
                      {
                        meta.mainProgram = "activate.nu";
                      } ''
                      mkdir -p $out/bin
                      cd $out/bin
                      echo "#!${pkgs.nushell}/bin/nu" >> activate.nu
                      echo "use nix.nu useRuntimeInputs" >> activate.nu
                      echo "useRuntimeInputs" >> activate.nu
                      cat ${./activate/activate.nu} >> activate.nu
                      chmod a+x activate.nu
                      cp ${nixosFlakeNuModule} nixos-flake.nu
                      cp ${nixNuModule} nix.nu
                    '';
                  in
                  nuPackage;
              in
              mkActivateApp {
                flake = self;
              };

            activate-home =
              if hasNonEmptyAttr [ "homeConfigurations" ] self || hasNonEmptyAttr [ "legacyPackages" system "homeConfigurations" ] self
              then
                pkgs.writeShellApplication
                  {
                    name = "activate-home";
                    text =
                      ''
                        set -x
                        nix run \
                          .#homeConfigurations."\"''${USER}\"".activationPackage \
                          "$@"
                      '';
                  }
              else null;
          };
        };
      });
  };

  config = {
    flake = {
      nixosModules.nixosFlake = ./nix/nixos-module.nix;
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

      darwinModules_.nixosFlake = ./nix/nixos-module.nix;
      # macOS home-manager module
      # This is named with an underscope, because flake-parts segfaults otherwise!
      # See https://github.com/srid/nixos-config/issues/31
      darwinModules_.home-manager = {
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
          modules = [
            mod
          ];
        };
      };
    };
  };
}
