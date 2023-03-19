# nixos-flake

A [flake-parts](https://flake.parts/) module to manage NixOS and macOS machines, along with home-manager support, in a unified fashion.

See https://github.com/srid/nixos-config for an example of a project using this module.

## Usage

We provide three templates, depending on your needs:

|Template | Command | Description |
| -- | -------- | ----------- |
| Both platforms | `nix flake init -t github:srid/nixos-flake` | NixOS, nix-darwin, home-manager configuration combined, with common modules |
| NixOS only | `nix flake init -t github:srid/nixos-flake#linux` | NixOS configuration only, with home-manager |
| macOS only | `nix flake init -t github:srid/nixos-flake#macos` | nix-darwin configuration only, with home-manager |

Once you have created the flake template, open the generated `flake.nix` and change the user (from "john") and hostname (from "example1") to match that of your environment; then run `nix run .#activate` to activate the configuration.

## Module

Importing this flake-parts module will autowire the following flake outputs:

| Name                         | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `nixos-flake.lib`             | Functions `mkLinuxSystem` and `mkDarwinSystem` |
| `nixosModules.home-manager`  | Home-manager setup module for NixOS            |
| `darwinModules.home-manager` | Home-manager setup module for Darwin           |
| `packages.update`            | Flake app to update key flake inputs            |
| `packages.activate`          | Flake app to build & activate the system       |

In addition, all of your NixOS/nix-darwin/home-manager modules implicitly receive the following `specialArgs`:

- `flake@{self, inputs, config}` (`config` is from flake-parts')
- `rosettaPkgs` (if on darwin)

The module API maybe be heavily refactored over the coming days/weeks. [All feedback welcome](https://github.com/srid/nixos-flake/issues/new).
