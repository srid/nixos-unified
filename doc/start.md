---
order: -10
---

# Getting Started

Pick your desired operating system and follow the below instructions.

## NixOS

1. [Install NixOS](https://nixos.org/download.html)
1. [Enable Flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes)
1. Flakify your `/etc/nixos/configuration.nix`: https://nixos.wiki/wiki/Flakes#Using_nix_flakes_with_NixOS
1. Convert your `flake.nix` to using `nixos-flake` using the [[templates|NixOS only template]] as reference.

## non-NixOS Linux

1. [Install Nix](https://haskell.flake.page/nix)
1. Use the [[templates|$HOME only template]]

## macOS

1. [Install Nix](https://haskell.flake.page/nix)
1. [Install nix-darwin](https://github.com/LnL7/nix-darwin)
1. Use the [[templates|macOS only template]][^both]

[^both]: Alternative, use the "Both platforms" template if you are sharing your configuration with the other platform as well.