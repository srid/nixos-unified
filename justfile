# Documentation targets
mod doc

default:
    @just --list

# Run CI locally
ci:
    om ci --extra-access-tokens "github.com=$(gh auth token)"

# Auto-format the Nix files in project tree
fmt:
    treefmt
