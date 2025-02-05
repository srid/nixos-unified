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
├── 📁 flake
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
| `modules/flake/foo.nix`                   | `flakeModules.foo`                                          |
| `overlays/foo.nix`                        | `overlays.foo`                                              |

## flake-parts

Autowiring is also provided if you use just flake-parts, via the `lib.mkFlake` function. In your top-level flake.nix, you only need to define your `outputs` as follows:

```nix
{
  inputs = ...;
  outputs = inputs:
    inputs.nixos-unified.lib.mkFlake
      { inherit inputs; root = ./.; };
}
```

This will,

- Auto-import flake-parts modules under either `./nix/modules/flake` or `./modules/flake` (whichever exists)
- Use a sensible default for `systems` which can be overriden.
- Pass `root` as top-level module args, as a non-recursive way of referring to the path of the flake (without needing `inputs.self`).

See [srid/haskell-template's flake.nix](https://github.com/srid/haskell-template/blob/master/flake.nix) for a ready example. For another example, see [this emanote PR](https://github.com/srid/emanote/pull/558).

[^default]: This path could as well be `configurations/nixos/foo/default.nix`. Likewise for other output types.

[^hm-pkgs]: Why `legacyPackages`? Because, creating a home-manager configuration [requires `pkgs`](https://github.com/srid/nixos-unified/blob/47a26bc9118d17500bbe0c4adb5ebc26f776cc36/nix/modules/flake-parts/lib.nix#L97). See <https://github.com/nix-community/home-manager/issues/3075>
