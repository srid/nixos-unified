set -euo pipefail

if [ "$(uname)" == "Darwin" ]; then
  CONF="darwinConfigurations.example1"
else
  CONF="nixosConfigurations.example1"
fi

nix build \
  --override-input nixos-flake ../.. \
  .#activate
nix build \
  --override-input nixos-flake ../.. \
  .#update
nix build \
  --override-input nixos-flake ../.. \
  .#${CONF}.config.system.build.toplevel

ls result/
rm -f result flake.lock