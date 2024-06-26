
# Activation

`nixos-flake` provides the `.#activate` flake app that can be used in place of `nixos-rebuild` (if using NixOS) and `darwin-rebuild` (if using `nix-darwin`).

In addition, it can also activate the system over SSH -- see next section.

```sh
nix run .#activate
```

Usually, you'd make this your default package, so as to be able to use `nix run`. In `flake.nix`:

```nix
# In perSystem
{
    packages.default = self'.packages.activate
}
```


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

### Non-goals

Remote activation doesn't seek to replace other deployment tools, and as such doesn't provide features like rollbacks. It is meant for simple deployment use cases. 

>[!NOTE] Future
> It is possible however that `nixos-flake` can grow to support more sophisticated deployment capabilities