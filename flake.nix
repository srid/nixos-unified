{
  outputs = _: rec {
    flakeModules = {
      default = ./nix/modules/flake-parts;
      autoWire = ./nix/modules/flake-parts/autowire.nix;
    };
    # For backwards compat only
    flakeModule = flakeModules.default;

    # Like flake-parts mkFlake, but auto-imports modules/flake-parts, consistent with autowiring feature.
    #
    # Looks under either nix/modules/flake-parts or modules/flake-parts for modules to import. `systems` is set to a default value. `root` is passed as top-level module args (as distinct from `inputs.self` the use of which can lead to infinite recursion).
    lib.mkFlake =
      { inputs
      , root
      , systems ? [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ]
      , specialArgs ? { }
      }:
      inputs.flake-parts.lib.mkFlake { inherit inputs specialArgs; } {
        inherit systems;
        _module.args = { inherit root; };
        imports = with builtins;
          if pathExists "${root}/nix/modules/flake-parts" then
            map
              (fn: "${root}/nix/modules/flake-parts/${fn}")
              (attrNames (readDir (root + /nix/modules/flake-parts)))
          else if pathExists "${root}/modules/flake-parts" then
            map
              (fn: "${root}/modules/flake-parts/${fn}")
              (attrNames (readDir (root + /modules/flake-parts)))
          else
            throw "Neither modules/flake-parts nor nix/modules/flake-parts exist";
      };

    templates =
      let
        tmplPath = path: builtins.path { inherit path; filter = path: _: baseNameOf path != "test.sh"; };
      in
      {
        linux = {
          description = "nixos-unified template for NixOS configuration.nix";
          path = tmplPath ./examples/linux;
        };
        macos = {
          description = "nixos-unified template for nix-darwin configuration";
          path = tmplPath ./examples/macos;
        };
        home = {
          description = "nixos-unified template for home-manager configuration";
          path = tmplPath ./examples/home;
        };
      };

    om = {
      templates = rec {
        home = {
          template = templates.home;
          params = [
            {
              name = "username";
              description = "The $USER to apply home-manager configuration on";
              placeholder = "john";
            }
          ];
        };

        macos = {
          template = templates.macos;
          params = home.params ++ [
            {
              name = "hostname";
              description = "Hostname of the machine";
              placeholder = "example1";
            }
          ];
        };

        linux = {
          template = templates.linux;
          inherit (macos) params;
        };
      };

      ci.default = let overrideInputs = { nixos-unified = ./.; }; in {
        docs.dir = "doc";
        macos = {
          inherit overrideInputs;
          dir = "examples/macos";
          systems = [ "x86_64-darwin" "aarch64-darwin" ];
        };
        home = {
          inherit overrideInputs;
          dir = "examples/home";
        };
        linux = {
          inherit overrideInputs;
          dir = "examples/linux";
          systems = [ "x86_64-linux" "aarch64-linux" ];
        };
      };
    };
  };
}
