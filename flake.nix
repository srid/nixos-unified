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
        imports =
          let
            # Patterns to search in order
            candidates = [
              # These correspond to `flakeModules.*`
              "nix/modules/flake"
              "modules/flake"
              # Just for backwards compatbility
              "nix/modules/flake-parts"
              "modules/flake-parts"
            ];
            getModulesUnderFirst = cs: with builtins;
              if cs == [ ] then throw "None of these paths exist: ${toString candidates}"
              else if pathExists "${root}/${head cs}"
              then
                map (fn: "${root}/${head cs}/${fn}") (attrNames (readDir (root + /${head cs})))
              else getModulesUnderFirst (tail cs);
          in
          getModulesUnderFirst candidates;
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
    };
  };
}
