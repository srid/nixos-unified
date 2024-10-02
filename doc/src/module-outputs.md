# Module outputs

Importing the `nixos-unified` flake-parts module will autowire the following flake outputs in your flake:

| Name                                   | Description                                                                                   |
| -------------------------------------- | --------------------------------------------------------------------------------------------- |
| **`nixos-unified.lib`**                | Functions `mkLinuxSystem`, `mkMacosSystem` and `mkHomeConfiguration`                          |
| **`packages.update`**                  | Flake app to update key flake inputs                                                          |
| [**`packages.activate`**](activate.md) | Flake app to build & activate the system (locally or remotely over SSH) or home configuration |

In addition, all of your NixOS/nix-darwin/home-manager modules implicitly receive the following `specialArgs`:

- `flake@{self, inputs, config}` (`config` is from flake-parts')
- `rosettaPkgs` (if on darwin)

[^home]: This will soon be removed in favour of the [activate app](activate.md). See <https://github.com/srid/nixos-unified/issues/18>
