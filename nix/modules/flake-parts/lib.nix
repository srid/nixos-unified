{ self, inputs, config, lib, ... }:
let
  specialArgsFor = rec {
    common = {
      flake = { inherit self inputs config; };
    };
    nixos = common;
    darwin = common // {
      rosettaPkgs = import inputs.nixpkgs { system = "x86_64-darwin"; };
    };
  };

  nixosModules = {
    # Linux home-manager module
    home-manager = {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgsFor.nixos;
        }
      ];
    };

    # Common and useful setting across all platforms
    common = { lib, ... }: {
      nix = {
        settings = {
          # Use all CPU cores
          max-jobs = lib.mkDefault "auto";
          # Duh
          experimental-features = lib.mkDefault "nix-command flakes";
        };
      };
    };
  };

  darwinModules = {
    # macOS home-manager module
    home-manager = {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgsFor.darwin;
          home-manager.sharedModules = [{
            home.sessionPath = [
              "/etc/profiles/per-user/$USER/bin" # To access home-manager binaries
              "/nix/var/nix/profiles/system/sw/bin" # To access nix-darwin binaries
              "/usr/local/bin" # Some macOS GUI programs install here
            ];
          }];
        }
      ];
    };
    # nix-darwin module containing necessary configuration
    # Required when using the DetSys installer
    # cf. https://github.com/srid/nixos-flake/issues/52
    nix-darwin = {
      nix.useDaemon = true; # Required on multi-user Nix install
    };
  };
in
{
  config = {
    flake = {
      nixos-flake.lib = {
        inherit specialArgsFor;

        mkLinuxSystem = { home-manager ? false }: mod: inputs.nixpkgs.lib.nixosSystem {
          # Arguments to pass to all modules.
          specialArgs = specialArgsFor.nixos;
          modules = [
            ../configurations
            nixosModules.common
            mod
          ] ++ lib.optional home-manager nixosModules.home-manager;
        };

        mkMacosSystem = { home-manager ? false }: mod: inputs.nix-darwin.lib.darwinSystem {
          specialArgs = specialArgsFor.darwin;
          modules = [
            ../configurations
            nixosModules.common
            darwinModules.nix-darwin
            mod
          ] ++ lib.optional home-manager darwinModules.home-manager;
        };

        mkHomeConfiguration = pkgs: mod: inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = specialArgsFor.common;
          modules = [ mod ];
        };
      };
    };
  };
}
