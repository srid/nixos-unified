{ self, inputs', pkgs, lib, system, ... }:

let
  nixosFlakeNuModule =
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
    in
    pkgs.writeTextFile {
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
    ];
  extraBuildCommand = ''
    cp ${nixosFlakeNuModule} nixos-flake.nu
  '';
}
