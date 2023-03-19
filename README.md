# nixos-flake

**!! WIP !!**

A [flake-parts](https://flake.parts/) module to manage NixOS and macOS machines, along with home-manager support, in a unified fashion.

See https://github.com/srid/nixos-config for an example of a project using this module.

## Usage

We provide three templates, depending on your needs:

| Template | Description |
| -------- | ----------- |
| `nix flake init -t github:srid/nixos-flake` | NixOS and nix-darwin configuration, with common modules |
| `nix flake init -t github:srid/nixos-flake#linux` | NixOS configuration only, with home-manager |
| `nix flake init -t github:srid/nixos-flake#macos` | nix-darwin configuration only, with home-manager |

Once you have created the flake template, open the generated `flake.nix` and change the user (from "john") and hostname (from "example1") to match that of your environment; then run `nix run .#activate` to activate the configuration.

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

- `flake@{self, inputs, config}` (corresponding to flake-parts' arguments)
- `rosettaPkgs` (if on darwin)

The module API will be heavily refactored over the coming days/weeks. DO NOT USE THIS PROJECT YET.
