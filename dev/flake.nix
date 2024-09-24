{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixos-flake.url = "github:srid/nixos-flake";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      perSystem = { pkgs, lib, config, ... }: {
        treefmt.config = {
          projectRoot = inputs.haskell-flake;
          projectRootFile = "README.md";
          programs.nixpkgs-fmt.enable = true;
        };
        devShells.default = pkgs.mkShell {
          # cf. https://community.flake.parts/haskell-flake/devshell#composing-devshells
          inputsFrom = [
            config.treefmt.build.devShell
          ];
          packages = with pkgs; [
            just
          ];
          shellHook = ''
            echo
            echo "🍎🍎 Run 'just <recipe>' to get started"
            just
          '';
        };
      };
    };
}
