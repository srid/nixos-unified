# nixos-flake

**!! WIP !!**

A flake-parts module, extracting common stuff out of https://github.com/srid/nixos-config. We aim to support Linux (NixOS), macOS and home-manager, unified as a single flake.

## Usage

To create a nixos configuration project using this module, run:

```sh
nix flake init -t github:srid/nixos-flake
```

Change the hostname (from "example1") and run `nix run .#activate` as appropriate.

## Module

The `flakeModule` (flake-parts module) contains the following:

| Name                         | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `nixos-flake.lib`             | Functions `mkLinuxSystem` and `mkDarwinSystem` |
| `nixosModules.home-manager`  | Home-manager setup module for NixOS            |
| `darwinModules.home-manager` | Home-manager setup module for Darwin           |
| `packages.update`            | Flake app to update key flake inputs            |
| `packages.activate`          | Flake app to build & activate the system       |

In addition, all modules implicitly receive the following `specialArgs`:

- `flake@{inputs, config}` (corresponding to flake-parts' arguments)
- `rosettaPkgs` (if on darwin)

The module API will be heavily refactored over the coming days/weeks. DO NOT USE THIS PROJECT YET.
