---
short-title: nixos-flake ❄️
template:
  sidebar:
    collapsed: true
emanote:
  folder-folgezettel: false
---

# Managing OS and home configurations using `nixos-flake`

[nixos-flake](https://github.com/srid/nixos-flake) a [flake-parts](https://flake.parts/) module to unify [NixOS](https://nixos.org/manual/nixos/stable/) + [nix-darwin](https://github.com/LnL7/nix-darwin) + [home-manager] configuration in a single flake, while providing a consistent interface (and enabling common modules) for both Linux and macOS.

## Why?

nixos-flake provides the following features:

- **One-click activation & deployment**
  - [[activate]]: An `.#activate` flake app that works both on macOS and NixOS.
    - `.#activate` can also *remotely* activate machines (be it macOS or NixOS) over SSH, thus acting as a simple alternative to deployment tools like `deploy-rs` and `colmena`.
  - Also: an `.#update` flake app to update the primary inputs (which can be overriden)
- **Seamless access to top-level flake**
  - All NixOS/ nix-darwin/ home-manager modules receive `specialArgs` which includes all the information in the top-level flake.
    - This enables those modules to be aware of the flake inputs, for instance.
- **Sensible defaults**
  - Sensible defaults for home-manager/ nix-darwin/ and NixOS configurations ([\#75](https://github.com/srid/nixos-flake/pull/75)).

## Getting Started

See: [[start]]# and [[guide]]#. For examples, see [[examples]]#

[home-manager]: https://github.com/nix-community/home-manager
