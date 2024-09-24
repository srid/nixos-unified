{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-flake.url = "github:srid/nixos-flake";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      imports = [ inputs.nixos-flake.flakeModule ];

      flake =
        let
          myUserName = "john";
        in
        {
          # Configurations for macOS machines
          darwinConfigurations."example1"" = self.nixos-flake.lib.mkMacosSystem {
            nixpkgs.hostPlatform = "aarch64-darwin";
            imports = [
              self.darwinModules_.nix-darwin
              # Your nix-darwin configuration goes here
              ({ pkgs, ... }: {
                # https://github.com/nix-community/home-manager/issues/4026#issuecomment-1565487545
                users.users.${myUserName}.home = "/Users/${myUserName}";

                security.pam.enableSudoTouchIdAuth = true;

                # Used for backwards compatibility, please read the changelog before changing.
                # $ darwin-rebuild changelog
                system.stateVersion = 4;
              })
              # Setup home-manager in nix-darwin config
              self.darwinModules_.home-manager
              {
                home-manager.users.${myUserName} = {
                  imports = [ self.homeModules.default ];
                  home.stateVersion = "22.11";
                };
              }
            ];
          };

          # home-manager configuration goes here.
          homeModules.default = { pkgs, ... }: {
            imports = [ ];
            programs.git.enable = true;
            programs.starship.enable = true;
            programs.zsh.enable = true;
          };
        };
    };
}
