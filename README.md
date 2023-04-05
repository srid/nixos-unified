# nixos-flake

A [flake-parts](https://flake.parts/) module to unify [NixOS](https://nixos.org/manual/nixos/stable/) + [nix-darwin](https://github.com/LnL7/nix-darwin) + [home-manager] configuration in a single flake, while providing a consistent interface (and enabling common modules) for both Linux and macOS.

[home-manager]: https://github.com/nix-community/home-manager

## Usage

We provide four templates, depending on your needs:

|Template | Command | Description |
| -- | -------- | ----------- |
| Both platforms | `nix flake init -t github:srid/nixos-flake` | NixOS, nix-darwin, home-manager configuration combined, with common modules |
| NixOS only | `nix flake init -t github:srid/nixos-flake#linux` | NixOS configuration only, with home-manager |
| macOS only | `nix flake init -t github:srid/nixos-flake#macos` | nix-darwin configuration only, with home-manager |
| Other Linux distros / $HOME only | `nix flake init -t github:srid/nixos-flake#home` | [home-manager] configuration only (useful if you use other Linux distros or do not have admin access to the machine) |

After initializing the template, open the generated `flake.nix` and change the user (from "john") as well as hostname (from "example1") to match that of your environment (Run `echo $USER` and `hostname -s` to determine the new values).[^intel] Then run `nix run .#activate` (`nix run .#activate-home` if you are using the 4th template) to activate the configuration.

[^intel]: If you are on an Intel Mac, change `mkARMMacosSystem` to `mkIntelMacosSystem`.

## Module outputs

Importing this flake-parts module will autowire the following flake outputs:

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

The module API maybe be heavily refactored over the coming days/weeks. [All feedback welcome](https://github.com/srid/nixos-flake/issues/new).

## Examples

- https://github.com/srid/nixos-config (using `#both` template)
- https://github.com/hkmangla/nixos (using `#linux` template)
- https://github.com/juspay/nix-dev-home (using `#home` template)
