set -euo pipefail

if [ "$(uname)" == "Darwin" ]; then
  CONF="darwinConfigurations.default"
else
  CONF="nixosConfigurations.example1"
fi

nix build .#${CONF}.config.system.build.toplevel
ls result/
rm result flake.lock