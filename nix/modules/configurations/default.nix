# A NixOS/nix-darwin module to specify nixos-unified metadata for configurations.
#
# FIXME: Using this module in home-manager leads to `error: infinite recursion
# encountered` on `id = x: x`
{ flake, config, lib, ... }:
let
  inherit (flake) inputs;
in
{
  options = {
    nixos-unified = {
      sshTarget = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          SSH target for this system configuration.
        '';
      };
      overrideInputs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          List of flake inputs to override when deploying or activating.
        '';
      };
      outputs = {
        system = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = config.nixpkgs.hostPlatform.system;
          description = ''
            System to activate.
          '';
        };
        overrideInputs = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          readOnly = true;
          default = lib.foldl' (acc: x: acc // { "${x}" = inputs.${x}; }) { } config.nixos-unified.overrideInputs;
        };
        nixArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          readOnly = true;
          default = (builtins.concatMap
            (name: [
              "--override-input"
              "${name}"
              "${inputs.${name}}"
            ])
            # TODO: Use `outputs.overrideInputs` instead.
            config.nixos-unified.overrideInputs);
          description = ''
            Arguments to pass to `nix`
          '';
        };
      };
    };
  };
}
