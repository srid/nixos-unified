default:
    @just --list

# Run CI locally
ci:
    om ci --extra-access-tokens "github.com=$(gh auth token)"

# Auto-format the Nix files in project tree
fmt:
    treefmt

# Open haskell-flake docs live preview
docs:
    cd ./doc && nix run
