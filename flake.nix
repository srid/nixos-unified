{
  outputs = _: rec {
    flakeModules = {
      default = ./nix/modules/flake-parts;
      autoWire = ./nix/modules/flake-parts/autowire.nix;
    };
    # For backwards compat only
    flakeModule = flakeModules.default;

    templates =
      let
        tmplPath = path: builtins.path { inherit path; filter = path: _: baseNameOf path != "test.sh"; };
      in
      {
        linux = {
          description = "nixos-flake template for NixOS configuration.nix";
          path = tmplPath ./examples/linux;
        };
        macos = {
          description = "nixos-flake template for nix-darwin configuration";
          path = tmplPath ./examples/macos;
        };
        home = {
          description = "nixos-flake template for home-manager configuration";
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

      ci.default = let overrideInputs = { nixos-flake = ./.; }; in {
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
