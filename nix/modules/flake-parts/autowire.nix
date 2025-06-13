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
        lib.optionalAttrs (builtins.pathExists dir)
          (mapAttrsMaybe
            (fn: type:
              let
                name = lib.removeSuffix ".nix" fn;
                path = "${dir}/${fn}";
              in
              if type == "regular" && name != fn then lib.nameValuePair name (f path)
              else if type == "directory" && builtins.pathExists "${path}/default.nix" then lib.nameValuePair fn (f path)
              else null
            )
            (builtins.readDir dir));
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
