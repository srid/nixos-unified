[![project chat](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://nixos.zulipchat.com/#narrow/stream/413948-nixos)

# nixos-flake

A [flake-parts](https://flake.parts/) module to unify [NixOS](https://nixos.org/manual/nixos/stable/) + [nix-darwin](https://github.com/LnL7/nix-darwin) + [home-manager] configuration in a single flake, while providing a consistent interface (and enabling common modules) for both Linux and macOS.


[home-manager]: https://github.com/nix-community/home-manager

## Why?

nixos-flake provides the following:

- The `.#activate` flake app that works both on macOS and NixOS.
  - `.#activate` can also *remote* activate machins (be it macOS or NixOS) over SSH.
- All NixOS/ nix-darwin/ home-manager modules receive `specialArgs` which includes all the information in the top-level flake.
  - This enables those modules to be aware of the flake inputs, for instance.
- A `.#update` flake app to update the primary inputs (which can be overriden)

## Getting Started

https://community.flake.parts/nixos-flake/start

## Discussion

To discuss the project, post in [our Zulip](https://nixos.zulipchat.com/#narrow/stream/413948-nixos) (preferred) or in [Github Discussions](https://github.com/srid/nixos-flake/discussions).
