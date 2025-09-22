---
order: 2
---


# Activation

`nixos-unified` provides an `.#activate` flake app that can be used in place of `nixos-rebuild switch` (if using NixOS),`darwin-rebuild switch` (if using `nix-darwin`) or `home-manager switch` (if using home-manager)

In addition, it can remotely activate the system over SSH (see further below).

## Activating NixOS or nix-darwin configurations {#system}


In order to activate a system configuration for the current host (`$HOSTNAME`), run:

```sh
nix run .#activate
```

> [!TIP]
> Usually, you'd make this your default package, so as to be able to use `nix run`. In `flake.nix`:
>
> ```nix
> # In perSystem
> {
>     packages.default = self'.packages.activate
> }
> ```

## Activating home configuration {#home}

If you are on a non-NixOS Linux (or on macOS but you do not use nix-darwin), you will have a home-manager configuration. Suppose, you have it stored in `legacyPackages.homeConfigurations."myuser"` (where `myuser` matches `$USER`), you can activate that by running:

```sh
nix run .#activate $USER@
```

> [!NOTE]
> The activate app will activate the home-manager configuration if the argument contains a `@` (separating user and the optional hostname). The above command has no hostname, indicating that we are activating for the local host.

> [!NOTE]
> The activate app will move your existing dotfiles out of the way with a timestamped backup extension. For example, your existing `~/.zshrc` will be backed up in `~/.zshrc.nixos-unified.2025-01-15-22:29:54.bak`.

### Per-host home configurations {#home-perhost}

You may also have separate home configurations for each machine, such as `legacyPackages.homeConfigurations."myuser@myhost"`. These can be activated using:

```sh
nix run .#activate $USER@$HOSTNAME
```

This will activate the home-manager configuration for the specified host over SSH (see below).

## Remote Activation {#remote}

`nixos-unified` acts as a lightweight alternative to the various deployment tools such as `deploy-rs` and `colmena`. The `.#activate` app takes the hostname as an argument and supports remote activation for both system configurations (NixOS/nix-darwin) and home-manager configurations.

### Remote System Activation {#remote-system}

For NixOS or nix-darwin configurations, set the `nixos-unified.sshTarget` option in your configuration:

```nix
{
    nixos-unified.sshTarget = "myuser@myhost";
}
```

Then, you will be able to run the following to deploy to `myhost` from any machine:

```sh
nix run .#activate myhost
```

### Remote Home-Manager Activation {#remote-home}

For home-manager configurations, remote activation works by specifying the user and hostname:

```sh
nix run .#activate myuser@myhost
```

This will:
1. Copy the flake and necessary inputs to the remote host via SSH
2. Run the home-manager activation remotely on the target machine

> [!NOTE]
> Remote home-manager activation uses the `user@host` format for the SSH connection, where the user is extracted from the configuration name and the host is the target machine.

### Non-goals

Remote activation doesn't seek to replace other deployment tools, and as such doesn't provide features like rollbacks. It is meant for simple deployment use cases.

> [!NOTE]
> It is possible however that `nixos-unified` can grow to support more sophisticated deployment capabilities
