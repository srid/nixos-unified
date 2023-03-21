set -euo pipefail

USER="john"

set -x
nix build \
  --override-input nixos-flake ../.. \
  .#activate-home
nix build \
  --override-input nixos-flake ../.. \
  .#update
nix build \
  --override-input nixos-flake ../.. \
  .#homeConfigurations.${USER}.activationPackage
set +x

ls result/
rm -f result flake.lock