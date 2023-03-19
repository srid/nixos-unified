set -euo pipefail

if [ "$(uname)" == "Darwin" ]; then
  CONF="darwinConfigurations.example1"

  nix build \
    --override-input nixos-flake ../.. \
    .#${CONF}.config.system.build.toplevel

  ls result/
  rm -f result flake.lock
else
  echo Skipped
fi
