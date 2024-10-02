{ stdenv, mdbook, mdbook-alerts, imagemagick, ... }:

stdenv.mkDerivation {
  name = "omnix-mdbook-site";
  src = ./.;

  buildInputs = [ imagemagick ];
  nativeBuildInputs = [
    mdbook
    mdbook-alerts
  ];

  buildPhase = ''
    mdbook build
  '';

  installPhase = ''
    mkdir -p $out
    cp -r book/* $out/

    # Override mdbook's favicon.png with our own, generated from favicon.svg
    convert -size 256x -background none \
      $out/favicon.svg  \
      $out/favicon.png
  '';
}
