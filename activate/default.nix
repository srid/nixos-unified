{ self, inputs', pkgs, lib, system, ... }:

let
  nixosFlakeNuModule =
    let
      # Workaround https://github.com/NixOS/nix/issues/8752
      cleanFlake = lib.cleanSourceWith {
        name = "nixos-unified-activate-flake";
        src = self;
      };
      nixos-unified-configs = lib.mapAttrs (name: value: value.config.nixos-unified) (self.nixosConfigurations or { } // self.darwinConfigurations or { });
      data = {
        nixos-unified-configs = nixos-unified-configs;
        system = system;
        cleanFlake = cleanFlake;
      };
      dataFile = pkgs.writeTextFile {
        name = "nixos-unified-activate-data";
        text = ''
          ${builtins.toJSON data}
        '';
      };
    in
    pkgs.writeTextFile {
      name = "nixos-unified.nu";
      text = ''
        export def getData [] {
          open ${dataFile} | from json
        }
      '';
    };
  nu = import ./nu.nix { inherit pkgs; };
in
nu.writeNushellApplication {
  name = "activate";
  scriptDir = ./.;
  meta = {
    mainProgram = "activate.nu";
    description = "Activate NixOS/nix-darwin/home-manager configurations";
  };
  runtimeInputs =
    # TODO: better way to check for nix-darwin availability
    lib.optionals (pkgs.stdenv.isDarwin && lib.hasAttr "nix-darwin" inputs') [
      inputs'.nix-darwin.packages.default # Provides darwin-rebuild
    ] ++ lib.optionals (lib.hasAttr "home-manager" inputs') [
      inputs'.home-manager.packages.default # Provides home-manager
    ] ++ [
      pkgs.nixos-rebuild
      pkgs.hostname
    ];
  extraBuildCommand = ''
    cp ${nixosFlakeNuModule} nixos-unified.nu
  '';
}
