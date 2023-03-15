{
  outputs = inputs: {
    flakeModule = ./flake-module.nix;
    templates.default = {
      description = "Example nixos-config using nixos-flake";
      path = builtins.path { path = ./example; filter = path: _: baseNameOf path != "test.sh"; };
    };
  };
}
