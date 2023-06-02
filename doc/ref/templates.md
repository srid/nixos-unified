---
slug: templates
---

# Flake Templates

We provide four templates, depending on your needs:

|Template | Command | Description |
| -- | -------- | ----------- |
| [Both platforms](https://github.com/srid/nixos-flake/tree/master/examples/both) | `nix flake init -t github:srid/nixos-flake` | NixOS, nix-darwin, home-manager configuration combined, with common modules |
| [NixOS only](https://github.com/srid/nixos-flake/tree/master/examples/linux) | `nix flake init -t github:srid/nixos-flake#linux` | NixOS configuration only, with home-manager |
| [macOS only](https://github.com/srid/nixos-flake/tree/master/examples/macos) | `nix flake init -t github:srid/nixos-flake#macos` | nix-darwin configuration only, with home-manager |
| [Other Linux distros / $HOME only](https://github.com/srid/nixos-flake/tree/master/examples/home) | `nix flake init -t github:srid/nixos-flake#home` | [home-manager] configuration only (useful if you use other Linux distros or do not have admin access to the machine) |

After initializing the template, open the generated `flake.nix` and change the user (from "john") as well as hostname (from "example1") to match that of your environment (Run `echo $USER` and `hostname -s` to determine the new values).[^intel] Then run `nix run .#activate` (`nix run .#activate-home` if you are using the 4th template) to activate the configuration.

[^intel]: If you are on an Intel Mac, change `mkARMMacosSystem` to `mkIntelMacosSystem`.

[home-manager]: https://github.com/nix-community/home-manager