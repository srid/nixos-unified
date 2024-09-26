# Flake Templates

We provide four templates, depending on your needs:

## Available templates

You can easily initialize one of our templates using [Omnix](https://omnix.page/om/init.html)[^no-omnix]:

[^no-omnix]: If you do not use Omnix, you must use `nix flake init`, and manually change the template values such as username and hostname.


{#nixos}
### NixOS only

NixOS configuration only, with [home-manager]

```sh
nix --accept-flake-config run github:juspay/omnix -- \
  init -o ~/nix-config github:srid/nixos-flake#linux
```

{#macos}
### macOS only

nix-darwin configuration only, with [home-manager]

```sh
nix --accept-flake-config run github:juspay/omnix -- \
  init -o ~/nix-config github:srid/nixos-flake#macos
```

{#home}
### Home only

[home-manager] configuration only (useful if you use other Linux distros or do not have admin access to the machine)

```bash
nix --accept-flake-config run github:juspay/omnix -- \
  init -o ~/nix-config github:srid/nixos-flake#home
```

## After initializing the template

Run `nix run .#activate` (`nix run .#activate $USER` if you are using the 4th template, "Home only") to activate the configuration.

- on macOS, if you get an error about `/etc/nix/nix.conf`, run:
  ```sh
  sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
  nix --extra-experimental-features "nix-command flakes" run .#activate
  ```
- on macOS, if you had used Determinate Systems nix-installer, you may want to [uninstall that Nix](https://github.com/LnL7/nix-darwin/issues/931#issuecomment-2075596824), such that we use the one provided by nix-darwin,
  ```sh
  sudo -i nix-env --uninstall nix
  ```

[^intel]: If you are on an Intel Mac, also change `nixpkgs.hostPlatform` accordingly.

[home-manager]: https://github.com/nix-community/home-manager
