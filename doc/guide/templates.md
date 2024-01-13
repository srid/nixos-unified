import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Flake Templates

We provide four templates, depending on your needs:

:::info Available Flake templates
<Tabs>
  <TabItem value="both" label="Both platforms">

  ```bash
  nix flake init -t github:srid/nixos-flake
  ```

  NixOS, nix-darwin, [home-manager] configuration combined, with common modules.

  </TabItem>
  <TabItem value="nixos" label="NixOS only">

  ```bash
  nix flake init -t github:srid/nixos-flake#linux
  ```

  NixOS configuration only, with [home-manager]

  </TabItem>
  <TabItem value="macos" label="macOS only">

  ```bash
  nix flake init -t github:srid/nixos-flake#macos
  ```

  nix-darwin configuration only, with [home-manager]
  </TabItem>
  <TabItem value="other-linux" label="Home only">

  ```bash
  nix flake init -t github:srid/nixos-flake#home
  ```

  [home-manager] configuration only (useful if you use other Linux distros or do not have admin access to the machine)

  </TabItem>
</Tabs>
:::

After initializing the template, 
1. open the generated `flake.nix` and change the user (from "john") as well as hostname (from "example1") to match that of your environment (Run `echo $USER` and `hostname -s` to determine the new values).[^intel] 
2. Then run `nix run .#activate` (`nix run .#activate-home` if you are using the 4th template) to activate the configuration.

[^intel]: If you are on an Intel Mac, change `mkARMMacosSystem` to `mkIntelMacosSystem`.

[home-manager]: https://github.com/nix-community/home-manager