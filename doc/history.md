---
order: 100
---

# Release history

## Unreleased

- autoWiring of flake outputs & `mkFlake`
- activate script
  - add `--dry-run` (#104)
  - Remote activation support for home-manager configurations (#143)
- home-manager
  - More unique backup filenames (#97)
  - Add a default `home.homeDirectory` based on the user's username (#117)
- Remove use of deprecated alias `--update-input` of `nix flake update`
- Use `sudo` when activating with nix-darwin (#130)
- Add an opt-in local NixOS activation mode that runs `nixos-rebuild` itself through `sudo`
- Fix `nix copy` command for legacy NixOS systems by adding experimental features flag (#138)
- Switch to runCommand since runCommandNoCC is dropped in newer nixpkgs (#147)
- Fix autowired packages to respect `meta.platforms` and `meta.badPlatforms` to avoid exposing platform-incompatible packages

## 0.2.0 (2024-10-03)

Initial release, branched from `nixos-flake`
