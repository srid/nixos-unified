set -euo pipefail

if [ "$(uname)" == "Darwin" ]; then
  CONF="darwinConfigurations.default"
else
  CONF="nixosConfigurations.example1"
fi

nix build \
  --override-input nixos-flake ../. \
  .#${CONF}.config.system.build.toplevel

ls result/
rm -f result flake.lock