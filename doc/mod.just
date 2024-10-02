default:
  @just --list doc

# Run mdbook live server
run:
  nix run .#serve

# Do link checks on docs
check:
  nix run .#linkCheck

# Build the static site
build:
  nix build
