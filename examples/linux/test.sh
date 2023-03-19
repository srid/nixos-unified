set -euo pipefail

if [ "$(uname)" == "Darwin" ]; then
  echo Skipped
else
  CONF="nixosConfigurations.example1"
  nix build \
    --override-input nixos-flake ../.. \
    .#${CONF}.config.system.build.toplevel

  ls result/
  rm -f result flake.lock

fi