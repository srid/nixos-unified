---
slug: /nixos-flake/templates
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Flake Templates

We provide four templates, depending on your needs:

:::info Available Flake templates
<Tabs>
  <TabItem value="both" label="Both Platforms">
  <pre><code>nix flake init -t github:srid/nixos-flake</code></pre>
  <p>NixOS, nix-darwin, home-manager configuration combined, with common modules</p>
  </TabItem>
  <TabItem value="nixos" label="NixOS">
  <pre><code>nix flake init -t github:srid/nixos-flake#linux</code></pre>
  <p>NixOS configuration only, with home-manager</p>
  </TabItem>
  <TabItem value="macos" label="macOS">
  <pre><code>nix flake init -t github:srid/nixos-flake#macos</code></pre>
  <p>nix-darwin configuration only, with home-manager</p>
  </TabItem>
  <TabItem value="other-linux" label="Home only">
  <pre><code>nix flake init -t github:srid/nixos-flake#home</code></pre>
  <p>home-manager configuration only (useful if you use other Linux distros or do not have admin access to the machine)</p>
  </TabItem>
</Tabs>
:::

After initializing the template, 
1. open the generated `flake.nix` and change the user (from "john") as well as hostname (from "example1") to match that of your environment (Run `echo $USER` and `hostname -s` to determine the new values).[^intel] 
2. Then run `nix run .#activate` (`nix run .#activate-home` if you are using the 4th template) to activate the configuration.

[^intel]: If you are on an Intel Mac, change `mkARMMacosSystem` to `mkIntelMacosSystem`.

[home-manager]: https://github.com/nix-community/home-manager