# Autowiring

An optional **autowiring** module is provided that will scan the directory structure and wire up the appropriate flake outputs automatically without you having to do it manually.

A ready demonstration is available in [nixos-unified-template](https://github.com/juspay/nixos-unified-template) as well as [srid/nixos-config](https://github.com/srid/nixos-config). In the latter, you will notice the following directory structure:

```
❮ lsd --tree --depth 1 configurations modules overlays packages
📁 configurations
├── 📁 darwin
├── 📁 home
└── 📁 nixos
📁 modules
├── 📁 darwin
├── 📁 flake-parts
├── 📁 home
└── 📁 nixos
📁 overlays
└── ❄️ default.nix
📁 packages
├── ❄️ git-squash.nix
├── ❄️ sshuttle-via.nix
└── 📁 twitter-convert
```

Each of these are wired to the corresponding flake output, as indicated in the below table:

| Directory                                 | Flake Output                                                |
| ----------------------------------------- | ----------------------------------------------------------- |
| `configurations/nixos/foo.nix`[^default]  | `nixosConfigurations.foo`                                   |
| `configurations/darwin/foo.nix`[^default] | `darwinConfigurations.foo`                                  |
| `configurations/home/foo.nix`[^default]   | `legacyPackages.${system}.homeConfigurations.foo`[^hm-pkgs] |
| `modules/nixos/foo.nix`                   | `nixosModules.foo`                                          |
| `modules/darwin/foo.nix`                  | `darwinModules.foo`                                         |
| `modules/flake-parts/foo.nix`             | `flakeModules.foo`                                          |
| `overlays/foo.nix`                        | `overlays.foo`                                              |

[^default]: This path could as well be `configurations/nixos/foo/default.nix`. Likewise for other output types.

[^hm-pkgs]: Why `legacyPackages`? Because, creating a home-manager configuration [requires `pkgs`](https://github.com/srid/nixos-unified/blob/47a26bc9118d17500bbe0c4adb5ebc26f776cc36/nix/modules/flake-parts/lib.nix#L97). See <https://github.com/nix-community/home-manager/issues/3075>
