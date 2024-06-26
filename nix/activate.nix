{ self, inputs', pkgs, lib, system, ... }:

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
        cat ${../activate/activate.nu} >> activate.nu
        chmod a+x activate.nu
        cp ${nixosFlakeNuModule} nixos-flake.nu
        cp ${nixNuModule} nix.nu
      '';
    in
    nuPackage;
in
mkActivateApp {
  flake = self;
}
