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
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }: {
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
                nixArgs = lib.mkOption {
                  type = types.listOf types.str;
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

            activate =
              if hasNonEmptyAttr [ "darwinConfigurations" ] self || hasNonEmptyAttr [ "nixosConfigurations" ] self
              then
                pkgs.writeShellApplication
                  {
                    name = "activate";
                    text =
                      # TODO: Replace with deploy-rs or (new) nixinate
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
          modules = [ mod ];
        };

        mkMacosSystem = mod: inputs.nix-darwin.lib.darwinSystem {
          specialArgs = specialArgsFor.darwin;
          modules = [ mod ];
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
