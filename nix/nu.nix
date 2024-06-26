# Nix support for working Nushell scripts
{ pkgs, ... }:
{
  # Like writeShellApplication but for Nushell scripts
  #
  # This function likely should be improved for general use.
  writeNushellApplication =
    { runtimeInputs ? [ ]
    , mainScript
    , scriptDir
    , extraBuildCommand ? ""
    }:
    let
      nixNuModule = pkgs.writeTextFile {
        name = "nix.nu";
        text = ''
          use std *
          let bins = '${builtins.toJSON (builtins.map (p: "${p}/bin") runtimeInputs)}' | from json
          if $bins != [] {
            log debug $"Adding runtime inputs to PATH: ($bins)"
            path add ...$bins
          }
        '';
      };
    in
    pkgs.runCommandNoCC mainScript
      {
        meta.mainProgram = mainScript;
      } ''
      mkdir -p $out/bin
      cp ${scriptDir}/*.nu $out/bin/
      chmod -R a+w $out/bin
      cd $out/bin
      rm -f ${mainScript}
      echo "#!${pkgs.nushell}/bin/nu" >> ${mainScript}
      cat ${scriptDir}/${mainScript} >> ${mainScript}
      chmod a+x ${mainScript}
      ${extraBuildCommand}
    '';

}
