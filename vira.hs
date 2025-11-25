-- CI configuration <https://vira.nixos.asia/>
\ctx pipeline ->
  let
    isMaster = ctx.branch == "master"
    nu = [("nixos-unified", ".")]
  in pipeline
     { build.systems =
        [ "x86_64-linux"
        , "aarch64-darwin"
        ]
     , build.flakes =
         [ "./doc" { overrideInputs = nu }
         , "./examples/macos" { overrideInputs = nu }
         , "./examples/home" { overrideInputs = nu }
         , "./examples/linux" { overrideInputs = nu }
         ]
     , signoff.enable = True
     , cache.url = if isMaster then Just "https://cache.nixos.asia/oss" else Nothing
     }
