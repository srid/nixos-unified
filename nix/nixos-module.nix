{ flake, config, lib, ... }: {
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
        default = lib.foldl' (acc: x: acc // { "${x}" = flake.inputs.${x}; }) { } config.nixos-flake.overrideInputs;
      };
      nixArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = (builtins.concatMap
          (name: [
            "--override-input"
            "${name}"
            "${flake.inputs.${name}}"
          ])
          config.nixos-flake.overrideInputs);
        description = ''
          Arguments to pass to `nix`
        '';
      };
    };
  };
}
