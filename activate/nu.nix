# Nix support for working Nushell scripts
#
# TODO: Migrate to this once merged,
# https://github.com/DeterminateSystems/nuenv/pull/27
{ pkgs, ... }:
{
  # Like writeShellApplication but for Nushell scripts
  #
  # This function likely should be improved for general use.
  writeNushellApplication =
    { name
    , runtimeInputs ? [ ]
    , scriptDir
    , extraBuildCommand ? ""
    , meta
    }:
    let
      nixNuModule = pkgs.writeTextFile {
        name = "nix.nu";
        text = ''
          use std *
          let bins = '${builtins.toJSON (builtins.map (p: "${p}/bin") runtimeInputs)}' | from json
          log debug $"Adding runtime inputs to PATH: ($bins)"
          if $bins != [] {
            path add ...$bins
          }
        '';
      };
    in
    pkgs.runCommand name
      {
        inherit meta;
      } ''
      mkdir -p $out/bin
      cp ${scriptDir}/*.nu $out/bin/
      chmod -R a+w $out/bin
      cd $out/bin
      rm -f ${meta.mainProgram}
      echo "#!${pkgs.nushell}/bin/nu" >> ${meta.mainProgram}
      cat ${nixNuModule} >> ${meta.mainProgram}
      cat ${scriptDir}/${meta.mainProgram} >> ${meta.mainProgram}
      chmod a+x ${meta.mainProgram}
      ${extraBuildCommand}
    '';

}
