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
        nixArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = (builtins.map (name: "--override-input ${name} ${inputs.${name}}") config.nixos-flake.overrideInputs);
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
              overrideInputs = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = ''
                  List of flake inputs to override when deploying or activating.
                '';
              };
              deploy = {
                enable = lib.mkOption {
                  type = types.bool;
                  default = false;
                  description = ''
                    Add flake app to remotely activate current host / home through SSH.
                  '';
                };
                sshTarget = lib.mkOption {
                  type = types.str;
                  description = ''
                    SSH target to deploy to.
                  '';
                };
              };
              outputs = {
                overrideInputs = lib.mkOption {
                  type = types.attrsOf types.path;
                  default = lib.foldl' (acc: x: acc // { "${x}" = inputs.${x}; }) { } config.nixos-flake.overrideInputs;
                };
                nixArgs = lib.mkOption {
                  type = types.str;
                  default = lib.concatStringsSep " " (builtins.map (name: "--override-input ${name} ${inputs.${name}}") config.nixos-flake.overrideInputs);
                  description = ''
                    Arguments to pass to `nix`
                  '';
                };
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
            activate-v2 =
              let
                mkDeployApp = { flake }:
                  let
                    # Workaround https://github.com/NixOS/nix/issues/8752
                    cleanFlake = lib.cleanSourceWith {
                      name = "nixos-flake-activate-flake";
                      src = flake;
                    };
                    # Gather `config.nixos-flake.sshTarget` from all nixosConfigurations and darwinConfigurations
                    # 
                    # Should output, { "hostname1" = "nix-infra@whatever"; ... } for every nixosConfiguration.hostname1 and such
                    nixos-flake-configs = lib.mapAttrs (name: value: value.config.nixos-flake) (self.nixosConfigurations or { } // self.darwinConfigurations or { });
                  in
                  mkNushellScript {
                    name = "nixos-flake-activate";
                    script = ''
                      use std log
                      let data = '${builtins.toJSON nixos-flake-configs}' | from json
                      def main [host: string] {
                        let CURRENT_HOSTNAME = (hostname | str trim)
                        let HOSTNAME = ($host | default $CURRENT_HOSTNAME)
                        let hostData = ($data | get $HOSTNAME)
                        ${lib.getExe pkgs.nushell} ${./activate.nu} $HOSTNAME ${system} ${cleanFlake} ($hostData | to json -r)
                      }
                    '';
                  };
              in
              mkDeployApp {
                flake = self;
                # inherit (config.nixos-flake.deploy) sshTarget;
              };

            activate =
              if hasNonEmptyAttr [ "darwinConfigurations" ] self || hasNonEmptyAttr [ "nixosConfigurations" ] self
              then
                pkgs.writeShellApplication
                  {
                    name = "activate";
                    text =
                      if system == "aarch64-darwin" || system == "x86_64-darwin" then
                        let
                          # This is used just to pull out the `darwin-rebuild` script.
                          # See also: https://github.com/LnL7/nix-darwin/issues/613
                          emptyConfiguration = self.nixos-flake.lib.mkMacosSystem { nixpkgs.hostPlatform = system; };
                        in
                        ''
                          HOSTNAME=$(hostname -s)
                          set -x
                          ${emptyConfiguration.system}/sw/bin/darwin-rebuild \
                            switch \
                            --flake "path:${self}#''${HOSTNAME}" \
                            ${config.nixos-flake.outputs.nixArgs} \
                            "$@"
                        ''
                      else
                        ''
                          HOSTNAME=$(hostname -s)
                          set -x
                          ${lib.getExe pkgs.nixos-rebuild} \
                            switch \
                            --flake "path:${self}#''${HOSTNAME}" \
                            ${config.nixos-flake.outputs.nixArgs} \
                            --use-remote-sudo \
                            "$@"
                        '';
                  }
              else null;

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
                          ${config.nixos-flake.outputs.nixArgs} \
                          .#homeConfigurations."\"''${USER}\"".activationPackage \
                          "$@"
                      '';
                  }
              else null;

            deploy =
              if config.nixos-flake.deploy.enable
              then
                let
                  mkDeployApp = { flake, sshTarget }:
                    let
                      name = lib.replaceStrings [ "@" ] [ "_" ] sshTarget;
                      # Workaround https://github.com/NixOS/nix/issues/8752
                      cleanFlake = lib.cleanSourceWith {
                        name = "${name}-flake";
                        src = flake;
                      };
                    in
                    pkgs.writeShellApplication {
                      name = "${name}-deploy";
                      runtimeInputs = [ pkgs.nix ];
                      text = ''
                        set -x
                        nix copy ${cleanFlake} --to ssh-ng://${sshTarget}
                        ${lib.concatStringsSep "\n" (builtins.map (name: "nix copy ${inputs.${name}} --to ssh-ng://${sshTarget}") config.nixos-flake.overrideInputs)}
                        ssh -t ${sshTarget} nix --extra-experimental-features \"nix-command flakes\" \
                          run \
                          ${config.nixos-flake.outputs.nixArgs} \
                          "${cleanFlake}#activate"
                      '';
                    };
                in
                mkDeployApp {
                  flake = self;
                  inherit (config.nixos-flake.deploy) sshTarget;
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
