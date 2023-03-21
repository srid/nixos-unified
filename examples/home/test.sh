set -euo pipefail

USER="john"

nix build \
  --override-input nixos-flake ../.. \
  .#activate-home
nix build \
  --override-input nixos-flake ../.. \
  .#update
nix build \
  --override-input nixos-flake ../.. \
  .#homeConfigurations.${USER}.activationPackage

ls result/
rm -f result flake.lock