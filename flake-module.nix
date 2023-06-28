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

            activate =
              pkgs.writeShellApplication {
                name = "activate";
                text =
                  # TODO: Replace with deploy-rs or (new) nixinate
                  if system == "aarch64-darwin" || system == "x86_64-darwin" then
                    let
                      # This is used just to pull out the `darwin-rebuild` script.
                      # See also: https://github.com/LnL7/nix-darwin/issues/613
                      emptyConfiguration = self.nixos-flake.lib.mkMacosSystem system { };
                    in
                    ''
                      HOSTNAME=$(hostname -s)
                      set -x
                      ${emptyConfiguration.system}/sw/bin/darwin-rebuild \
                        switch \
                        --flake .#"''${HOSTNAME}" \
                        "$@"
                    ''
                  else
                    ''
                      HOSTNAME=$(hostname -s)
                      set -x
                      ${lib.getExe pkgs.nixos-rebuild} \
                        switch \
                        --flake .#"''${HOSTNAME}" \
                        --use-remote-sudo \
                        "$@"
                    '';
              };

            activate-home =
              if (lib.hasAttr "homeConfigurations" self || lib.hasAttrByPath [ "legacyPackages" system "homeConfigurations" ] self)
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

        mkHomeConfiguration = pkgs: mod: inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = specialArgsFor.common;
          modules = [ mod ];
        };
      };
    };
  };
}
