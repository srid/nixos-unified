set -euo pipefail

if [ "$(uname)" == "Darwin" ]; then
  CONF="darwinConfigurations.default"
  # Github Action runners do not support M1 yet.
  nix run nixpkgs#sd mkARMMacosSystem mkIntelMacosSystem
else
  CONF="nixosConfigurations.example1"
fi

nix build \
  --override-input nixos-flake ../. \
  .#${CONF}.config.system.build.toplevel

ls result/
rm -f result flake.lock