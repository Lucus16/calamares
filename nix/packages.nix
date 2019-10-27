{ writeScriptBin
, stdenv
, ckbcomp
, makeWrapper
, callPackage
, calamares
}:
{
  calamaresWithConfig = stdenv.mkDerivation {
    name = "calamares-with-config";
    buildInputs = [ makeWrapper ];

    runCommand = ''
      mkdir -p $out
      cp -r ${calamares} $out
      wrapProgram ${calamares}/bin/calamares \
        --append PATH : ${ckbcomp}/bin
    '';
  };
}
