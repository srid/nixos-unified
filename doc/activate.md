
# Activation

`nixos-flake` provides the `.#activate` flake app that can be used in place of `nixos-rebuild` (if using NixOS) and `darwin-rebuild` (if using `nix-darwin`).

In addition, it can also activate the system over SSH -- see next section.

{#remote}
## Remote Activation

You can use `nixos-flake` as a lightweight alternative to the various deployment tools such as `deploy-rs` and `colmena`. The `.#activate` app takes the hostname as an argument. If you set the `nixos-flake.sshTarget` option in your NixOS or nix-darwin configuration, it will run activation over the SSH connection.

Add the following to your configuration -- `nixosConfigurations.myhost` or `darwinConfigurations.myhost` (depending on the platform):

```nix
{
    nixos-flake.sshTarget = "myuser@myhost";
}
```

Then, you will be able to run the following to deploy to `myhost` from any machine:

```sh
nix run .#activate host myhost
```
