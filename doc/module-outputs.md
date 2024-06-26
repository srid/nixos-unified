# Module outputs

Importing the `nixos-flake` flake-parts module will autowire the following flake outputs in your flake:

| Name                         | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| **nixos-flake.lib**             | Functions `mkLinuxSystem`, `mkMacosSystem` and `mkHomeConfiguration` |
| **nixosModules.home-manager**  | Home-manager setup module for NixOS            |
| **darwinModules_.home-manager**[^und] | Home-manager setup module for Darwin           |
| **packages.update**            | Flake app to update key flake inputs            |
| [[activate\|packages.activate]]          | Flake app to build & activate the system (locally or remotely over SSH)       |
| **packages.activate-home**[^home]          | Flake app to build & activate the `homeConfigurations` for current user       |

In addition, all of your NixOS/nix-darwin/home-manager modules implicitly receive the following `specialArgs`:

- `flake@{self, inputs, config}` (`config` is from flake-parts')
- `rosettaPkgs` (if on darwin)


[^home]: This will soon be removed in favour of the [[activate|activate app]]. See https://github.com/srid/nixos-flake/issues/18

[^und]: Why the underscore in `darwinModules_`? This is to workaround a segfault with flake-parts. See https://github.com/srid/nixos-config/issues/31