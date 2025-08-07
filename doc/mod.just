default:
  @just --list doc

# Run mdbook live server
run:
  nix run

# Build the static site
build:
  nix build
