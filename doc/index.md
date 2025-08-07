---
short-title: nixos-unified
template:
  sidebar:
    collapsed: true
emanote:
  folder-folgezettel: false
---

# nixos-unified

[**nixos-unified**](https://github.com/srid/nixos-unified) is a [flake-parts](https://flake.parts/) module to unify [NixOS] + [nix-darwin] + [home-manager] configuration in a single flake, while providing a consistent interface at DX and UX level.

[NixOS]: https://nixos.org/
[nix-darwin]: https://github.com/LnL7/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager

## Why?

nixos-unified provides the following features:

- **One-click activation & deployment**
  - [[activate]]: An `.#activate` flake app that works uniformly on [NixOS], [nix-darwin] and [home-manager].
    - [[activate#remote|Remote Activation]]: `.#activate` can also *remotely* activate machines (be it macOS or NixOS) over SSH, thus acting as a simple alternative to deployment tools like `deploy-rs` and `colmena`.
  - Also: an `.#update` flake app to update the primary inputs (which can be overriden)
- **Seamless access to top-level flake**
  - All [NixOS]/ [nix-darwin]/ [home-manager] modules receive [[specialArgs|specialArgs]] which includes all the information in the top-level flake.
    - This enables those modules to be aware of the flake inputs, for instance.
- **Sensible defaults**
  - Sensible defaults for [home-manager]/ [nix-darwin]/ and [NixOS] configurations ([\#75](https://github.com/srid/nixos-unified/pull/75)).
- **Autowiring** of flake outputs
  - [[autowiring]]: An optional module that will scan the directory structure and wire up the appropriate flake outputs automatically without you having to do it manually.

## Getting Started

See: [[start]].
