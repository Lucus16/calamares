{ writeScriptBin, ckbcomp, makeWrapper, callPackage, calamares, runCommandNoCC
, lib, glibc, xlibs, utillinux, writeText }:

let
  config = writeText "settings.conf" (builtins.toJSON {
    modules-search = [ "local" ../src/modules ];
    sequence = [
      { show = [ "welcome" "partition" "locale" "keyboard" "users" "summary" ]; }
      { exec = [ "partition" "mount" "os-nixos" ]; }
      { show = [ "finished" ]; }
    ];
    branding = "default";
    prompt-install = false;
    dont-chroot = false;
    oem-setup = false;
    disable-cancel = false;
    disable-cancel-during-exec = false;
  });

  keyboard-config = writeText "keyboard.conf" (builtins.toJSON {
    writeEtcDefaultKeyboard = false;
    convertedKeymapPath = "${xlibs.xkeyboardconfig}/share/X11/xkb";
  });

  partition-config = writeText "partition.conf" (builtins.toJSON {
  });

  welcome-config = writeText "welcome.conf" (builtins.toJSON {
    requirements = {
      requiredStorage = 4;
      requiredRam = 0.5;
      check = [];
      required = [];
    };
  });

  configDir = runCommandNoCC "calamares-config" { } ''
    mkdir -p $out/modules $out/qml $out/branding
    cp ${config} $out/settings.conf
    cp ${welcome-config} $out/modules/welcome.conf
    cp ${keyboard-config} $out/modules/keyboard.conf
    cp ${partition-config} $out/modules/partition.conf
    cp -r ${../src/branding/default} $out/branding/default
  '';

  path = lib.makeBinPath [ utillinux ckbcomp glibc ];

in {
  calamaresWithConfig =
    runCommandNoCC "calamares" { buildInputs = [ makeWrapper ]; } ''
      cp -r ${calamares} $out
      chmod -R u+w $out
      wrapProgram $out/bin/calamares \
        --set PATH ${path} \
        --add-flags -c \
        --add-flags ${configDir}
    '';
}
