{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      perSystem = { self', pkgs, ... }: {
        packages = rec {
          default = pkgs.callPackage ./. { };
          # The 404.html file has a bizare internal hash.
          without404 = pkgs.runCommand "site-no404" { } ''
            cp -r ${default} $out
            chmod -R u+w $out
            rm $out/404.html
          '';
        };

        # Check that links are working
        checks.linkCheck =
          pkgs.runCommand "linkCheck"
            {
              buildInputs = [ pkgs.html-proofer ];
            } ''
            # Ensure that the htmlproofer is using the correct locale
            export LANG=en_US.UTF-8
            # Run htmlproofer
            htmlproofer --disable-external ${self'.packages.without404}
            touch $out
          '';

        apps = {
          serve.program = pkgs.writeShellApplication {
            name = "serve";
            runtimeInputs = with pkgs; [
              mdbook
              mdbook-alerts
            ];
            text = ''
              set -x
              mdbook serve --open
            '';
          };

          # This is like `checks.doc-linkCheck`, but also does external link checks
          # (which is something we can't do in Nix due to sandboxing)
          linkCheck.program = pkgs.writeShellApplication {
            name = "linkCheck";
            runtimeInputs = [ pkgs.html-proofer ];
            text = ''
              set -x
              # Allow Github's line hashes
              htmlproofer \
                --disable-external \
                --no-check-external-hash \
                ${self'.packages.without404}
            '';
          };
        };
      };
    };
}
