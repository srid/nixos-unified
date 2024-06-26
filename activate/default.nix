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
      use std *
      let bins = '${builtins.toJSON (builtins.map (p: "${p}/bin") runtimeInputs)}' | from json
      if $bins != [] {
        log debug $"Adding runtime inputs to PATH: ($bins)"
        path add ...$bins
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
    cat ${nixNuModule} >> activate.nu
    # echo 'print $"PATH = ($env.PATH)"' >> activate.nu
    cat ${./activate.nu} >> activate.nu
    chmod a+x activate.nu
    cp ${nixosFlakeNuModule} nixos-flake.nu
  '';
in
nuPackage
