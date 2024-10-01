{ self, lib, ... }:
let
in
{
  config =
    let
      forAllNixFiles = dir: f:
        if builtins.pathExists dir then
          lib.pipe dir [
            builtins.readDir
            (lib.filterAttrs (_: type: type == "regular"))
            (lib.mapAttrs' (fn: _:
              let name = lib.removeSuffix ".nix" fn; in
              lib.nameValuePair name (f "${dir}/${fn}")
            ))
          ] else { };
    in
    {
      flake = {
        darwinConfigurations =
          forAllNixFiles "${self}/configurations/darwin"
            (fn: self.nixos-flake.lib.mkMacosSystem { home-manager = true; } fn);

        nixosConfigurations =
          forAllNixFiles "${self}/configurations/nixos"
            (fn: self.nixos-flake.lib.mkLinuxSystem { home-manager = true; } fn);

        darwinModules =
          forAllNixFiles "${self}/modules/darwin"
            (fn: fn);

        nixosModules =
          forAllNixFiles "${self}/modules/nixos"
            (fn: fn);

        homeModules =
          forAllNixFiles "${self}/modules/home"
            (fn: fn);

        overlays =
          forAllNixFiles "${self}/overlays"
            (fn: import fn self.nixos-flake.lib.specialArgsFor.common);
      };

      perSystem = { pkgs, ... }: {
        legacyPackages.homeConfigurations =
          forAllNixFiles "${self}/configurations/home"
            (fn: self.nixos-flake.lib.mkHomeConfiguration pkgs fn);
      };
    };
}
