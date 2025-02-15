# HOWTO

## Creating shared configuration {#config}

You may want to share certain configuration (such as username or email) across multiple modules. Here is how you can do it:

1. Create a flake-parts module to hold the config schema. For example, [`config-module.nix`](https://github.com/juspay/nixos-unified-template/blob/9eeeb6c1ab4287ac0a37a22e72f053a3de82ddbc/modules/flake/config-module.nix)
1. Define your configuration in your config file. For example, [`config.nix`](https://github.com/juspay/nixos-unified-template/blob/9eeeb6c1ab4287ac0a37a22e72f053a3de82ddbc/modules/flake/config.nix).
1. Use your configuration from any of NixOS/ nix-darwin/ home-manager modules through `flake` [specialArgs](specialArgs.md), specifically `flake.config`. For example, see [here](https://github.com/juspay/nixos-unified-template/blob/9eeeb6c1ab4287ac0a37a22e72f053a3de82ddbc/modules/home/git.nix#L3).