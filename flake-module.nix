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

  nixosFlakeModule = { config, lib, ... }: {
    options = {
      nixos-flake.sshTarget = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          SSH target for this system configuration.
        '';
      };
      nixos-flake.overrideInputs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          List of flake inputs to override when deploying or activating.
        '';
      };
      nixos-flake.outputs = {
        system = lib.mkOption {
          type = lib.types.str;
          default = config.nixpkgs.hostPlatform.system;
          description = ''
            System to activate.
          '';
        };
        overrideInputs = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = lib.foldl' (acc: x: acc // { "${x}" = inputs.${x}; }) { } config.nixos-flake.overrideInputs;
        };
        nixArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = (builtins.concatMap
            (name: [
              "--override-input"
              "${name}"
              "${inputs.${name}}"
            ])
            config.nixos-flake.overrideInputs);
          description = ''
            Arguments to pass to `nix`
          '';
        };
      };
    };
  };
in
{
  options = {
    perSystem = mkPerSystemOption ({ config, self', inputs', pkgs, system, ... }:
      let
        # An analogue to writeScriptBin but for Nushell rather than Bash scripts.
        # Taken from https://github.com/DeterminateSystems/nuenv/blob/970bfd5321a5ff55135993f956aa7ad445778151/lib/nuenv.nix#L63
        mkNushellScript =
          { name
          , script
          , runtimeInputs ? [ ]
          , bin ? name
          }:

          let
            nu = "${pkgs.nushell}/bin/nu";
          in
          pkgs.writeTextFile {
            inherit name;
            destination = "/bin/${bin}";
            text = ''
              #!${nu} 
              use std *
              let bins = '${builtins.toJSON (builtins.map (p: lib.getBin p) runtimeInputs)}' | from json
              if $bins != [] {
                path add ...$bins
              }

              ${script}
            '';
            executable = true;
          };
      in
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
                  in
                  mkNushellScript {
                    name = "nixos-flake-activate";
                    runtimeInputs =
                      # TODO: better way to check for nix-darwin availability
                      if pkgs.stdenv.isDarwin && lib.hasAttr "nix-darwin" inputs' then [
                        inputs'.nix-darwin.packages.default # Provides darwin-rebuild
                      ] else [
                        pkgs.nixos-rebuild
                      ];
                    script = ''
                      use std log
                      let CURRENT_HOSTNAME = (hostname | str trim)
                      let data = '${builtins.toJSON nixos-flake-configs}' | from json
                      # Activate system configuration of the given host
                      def 'main host' [
                        host: string # Hostname to activate (must match flake.nix name)
                      ] {
                        let HOSTNAME = ($host | default $CURRENT_HOSTNAME)
                        log info $"Activating (ansi green_bold)($HOSTNAME)(ansi reset) from (ansi green_bold)($CURRENT_HOSTNAME)(ansi reset)"
                        let hostData = ($data | get $HOSTNAME)
                        ${lib.getExe pkgs.nushell} ${./activate.nu} $HOSTNAME ${system} ${cleanFlake} ($hostData | to json -r)
                      }
                      # Activate system configuration of local machine
                      def main [] {
                        main host ($CURRENT_HOSTNAME)
                      }
                      # TODO: Implement this, resolving https://github.com/srid/nixos-flake/issues/18
                      def 'main home' [] {
                        log error "Home activation not yet supported; use .#activate-home instead"
                        exit 1
                      }
                    '';
                  };
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
      nixosModules.nixosFlake = nixosFlakeModule;
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

      darwinModules_.nixosFlake = nixosFlakeModule;
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
