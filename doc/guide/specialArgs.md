---
order: 3
---

# Module Arguments

Each of your NixOS, nix-darwin and home-manager modules implicitly receive a [`specialArgs`](https://nixos.asia/en/nix-modules) called `flake`.

The components of this `flake` attrset are:

| Name | Description |
| ---- | ----------- |
| `inputs` | The `inputs` of your flake; `inputs.self` referring to the flake itself |
| `config` | The flake-parts perSystem `config` |

[Here](https://github.com/srid/nixos-config/blob/a420e5f531172aef753b07a411de8e254207f5c6/modules/darwin/default.nix#L2-L5) is an example of how these can be used:

```nix
{ flake, pkgs, lib, ... }:
let
  inherit (flake) config inputs;
  inherit (inputs) self;
in
{
  imports = [
    # Reference a flake input directly from a nix-darwin module
    inputs.agenix.darwinModules.default
  ];

  # Reference an arbitrary flake-parts config
  home-manager.users.${config.me.username} = { };
}
```

While the above example uses a nix-darwin module, you can do the same on NixOS or home-manager modules.
