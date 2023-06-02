---
slug: module-outputs
---

# Module outputs

Importing the `nixos-flake` flake-parts module will autowire the following flake outputs in your flake:

| Name                         | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `nixos-flake.lib`             | Functions `mkLinuxSystem`, `mkDarwinSystem` and `mkHomeConfiguration` |
| `nixosModules.home-manager`  | Home-manager setup module for NixOS            |
| `darwinModules.home-manager` | Home-manager setup module for Darwin           |
| `packages.update`            | Flake app to update key flake inputs            |
| `packages.activate`          | Flake app to build & activate the system       |
| `packages.activate-home`          | Flake app to build & activate the `homeConfigurations` for current user       |

In addition, all of your NixOS/nix-darwin/home-manager modules implicitly receive the following `specialArgs`:

- `flake@{self, inputs, config}` (`config` is from flake-parts')
- `rosettaPkgs` (if on darwin)

**NOTE**: The module API is open to change. [All feedback welcome](https://github.com/srid/nixos-flake/issues/new).