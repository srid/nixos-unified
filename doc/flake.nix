{
  inputs = {
    community-flake-parts.url = "github:flake-parts/community.flake.parts/mod";
    nixpkgs.follows = "community-flake-parts/nixpkgs";
    flake-parts.follows = "community-flake-parts/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.community-flake-parts.flakeModules.default
      ];
      perSystem = {
        flake-parts-docs = {
          enable = true;
          modules."nixos-flake" = {
            path = ./.;
            pathString = "./doc";
          };
        };
      };
    };
}
