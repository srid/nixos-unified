{ self, lib, ... }:
{
  config =
    let
      # Combine mapAttrs' and filterAttrs
      #
      # f can return null if the attribute should be filtered out.
      mapAttrsMaybe = f: attrs:
        lib.pipe attrs [
          (lib.mapAttrsToList f)
          (builtins.filter (x: x != null))
          builtins.listToAttrs
        ];
      forAllNixFiles = dir: f:
        if builtins.pathExists dir then
          lib.pipe dir [
            builtins.readDir
            (mapAttrsMaybe (fn: type:
              if type == "regular" then
                let name = lib.removeSuffix ".nix" fn; in
                if name != fn then
                  lib.nameValuePair name (f "${dir}/${fn}")
                else
                  null
              else if type == "directory" && builtins.pathExists "${dir}/${fn}/default.nix" then
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

      perSystem = { pkgs, ... }: {
        legacyPackages.homeConfigurations =
          forAllNixFiles "${self}/configurations/home"
            (fn: self.nixos-unified.lib.mkHomeConfiguration pkgs fn);
      };
    };
}
