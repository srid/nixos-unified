{ self, flake-parts-lib, lib, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    types;
in
{
  options.perSystem = mkPerSystemOption ({ config, inputs', pkgs, system, ... }: {
    options.nixos-unified = lib.mkOption {
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
    config.packages = lib.filterAttrs (_: v: v != null) {
      update =
        let
          inputs = config.nixos-unified.primary-inputs;
        in
        pkgs.writeShellApplication {
          name = "update-main-flake-inputs";
          meta.description = "Update the primary flake inputs";
          text = ''
            nix flake update${lib.foldl' (acc: x: acc + " " + x) "" inputs}
          '';
        };

      # Activate the given (system or home) configuration
      activate = import ../../../activate { inherit self inputs' pkgs lib system; };
    };
  });
}
