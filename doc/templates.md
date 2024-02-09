# Flake Templates

We provide four templates, depending on your needs:

## Available templates

{#both}
### Both platforms

NixOS, nix-darwin, [home-manager] configuration combined, with common modules.

```bash
nix flake init -t github:srid/nixos-flake
```

{#nixos}
### NixOS only

NixOS configuration only, with [home-manager]

```sh
nix flake init -t github:srid/nixos-flake#linux
```

{#macos}
### macOS only

nix-darwin configuration only, with [home-manager]

```sh
nix flake init -t github:srid/nixos-flake#macos
```

{#home}
### Home only

[home-manager] configuration only (useful if you use other Linux distros or do not have admin access to the machine)

```bash
nix flake init -t github:srid/nixos-flake#home
```

## After initializing the template

1. open the generated `flake.nix` and change the user (from "john") as well as hostname (from "example1") to match that of your environment (Run `echo $USER` and `hostname -s` to determine the new values).[^intel] 
2. Then run `nix run .#activate` (`nix run .#activate-home` if you are using the 4th template) to activate the configuration.

[^intel]: If you are on an Intel Mac, change `mkARMMacosSystem` to `mkIntelMacosSystem`.

[home-manager]: https://github.com/nix-community/home-manager