{
  outputs = inputs: {
    flakeModule = ./flake-module.nix;
    templates.default = {
      description = "Example nixos-config using nixos-flake";
      path = ./example;
    };
  };
}
