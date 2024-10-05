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
            (lib.mapAttrs' (fn: type:
              if type == "regular" then
                let name = lib.removeSuffix ".nix" fn; in
                lib.nameValuePair name (f "${dir}/${fn}")
              else if type == "directory" then
                lib.nameValuePair fn (f "${dir}/${fn}")
              else
                null
            ))
          ] else { };
    in
    {
      flake = {
        darwinConfigurations =
          forAllNixFiles "${self}/configurations/darwin"
            (fn: self.nixos-unified.lib.mkMacosSystem { home-manager = true; } fn);

        nixosConfigurations =
          forAllNixFiles "${self}/configurations/nixos"
            (fn: self.nixos-unified.lib.mkLinuxSystem { home-manager = true; } fn);

        homeConfigurations =
          forAllNixFiles "${self}/configurations/home"
            (fn: self.nixos-unified.lib.mkHomeConfiguration fn);

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
            (fn: import fn self.nixos-unified.lib.specialArgsFor.common);
      };
    };
}
