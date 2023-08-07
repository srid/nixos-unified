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

        mkMacosHomeManagerSystem = mod: inputs.nix-darwin.lib.darwinSystem {
          specialArgs = specialArgsFor.darwin;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ({
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgsFor.darwin;
            })
          ] ++[ mod ];
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
