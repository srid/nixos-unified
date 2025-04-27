{
  inputs = {
    # Principle inputs (updated by `nix run .#update`)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-unified.url = "github:srid/nixos-unified";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      imports = [ inputs.nixos-unified.flakeModules.default ];

      flake =
        let
          myUserName = "john";
        in
        {
          # Configurations for macOS machines
          darwinConfigurations."example1" =
            self.nixos-unified.lib.mkMacosSystem
              { home-manager = true; }
              {
                nixpkgs.hostPlatform = "aarch64-darwin";
                imports = [
                  # Your nix-darwin configuration goes here
                  ({ pkgs, ... }: {
                    # https://github.com/nix-community/home-manager/issues/4026#issuecomment-1565487545
                    users.users.${myUserName}.home = "/Users/${myUserName}";

                    security.pam.services.sudo_local.touchIdAuth = true;

                    # Used for backwards compatibility, please read the changelog before changing.
                    # $ darwin-rebuild changelog
                    system.stateVersion = 6;
                  })
                  # Setup home-manager in nix-darwin config
                  {
                    home-manager.users.${myUserName} = {
                      imports = [ self.homeModules.default ];
                      home.stateVersion = "24.11";
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
