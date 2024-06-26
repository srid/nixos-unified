{ self, inputs', pkgs, lib, system, ... }:

let
  # Workaround https://github.com/NixOS/nix/issues/8752
  cleanFlake = lib.cleanSourceWith {
    name = "nixos-flake-activate-flake";
    src = self;
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
  nu = import ../nix/nu.nix { inherit pkgs; };
in
nu.writeNushellApplication {
  scriptDir = ./.;
  mainScript = "activate.nu";
  runtimeInputs =
    # TODO: better way to check for nix-darwin availability
    if pkgs.stdenv.isDarwin && lib.hasAttr "nix-darwin" inputs' then [
      inputs'.nix-darwin.packages.default # Provides darwin-rebuild
    ] else [
      pkgs.nixos-rebuild
    ];
  extraBuildCommand = ''
    cp ${nixosFlakeNuModule} nixos-flake.nu
  '';
}
