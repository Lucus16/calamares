{ writeScriptBin, ckbcomp, makeWrapper, callPackage, calamares, runCommandNoCC
, lib, glibc, xlibs, utillinux, writeText, os-prober, lvm2, writeShellScriptBin
, systemd, xfsprogs, e2fsprogs, coreutils, mkpasswd }:
let
  path = lib.makeBinPath [
    ckbcomp
    coreutils
    e2fsprogs
    glibc
    lvm2
    os-prober
    udevsettle
    utillinux
    xfsprogs
    mkpasswd
    "/run/current-system/sw"
  ];

  config = writeText "settings.conf" (builtins.toJSON {
    modules-search = [ "local" ../src/modules ];
    sequence = [
      {
        show = [ "welcome" "partition" "locale" "keyboard" "users" "summary" ];
      }
      { exec = [ "partition" "mount" "os-nixos" "umount" ]; }
      { show = [ "finished" ]; }
    ];
    branding = "nixos";
    prompt-install = false;
    dont-chroot = false;
    oem-setup = false;
    disable-cancel = false;
    disable-cancel-during-exec = false;
  });

  branding-desc = writeText "branding.desc" (builtins.toJSON {
    componentName = "nixos";

    images = {
      productIcon = "nixos.png";
      productLogo = "nixos.png";
      productWelcome = "languages.png";
    };
    slideshow = "show.qml";
    strings = with lib.trivial; {
      bootloaderEntryName = "NixOS";
      knownIssuesUrl =
        "https://github.com/NixOS/nixpkgs/labels/6.topic%3A%20nixos";
      productName = "NixOS";
      productUrl = "https://nixos.org/";
      releaseNotesUrl =
        "https://nixos.org/nixos/manual/release-notes.html#sec-release-@nixosRelease@";
      shortProductName = "NixOS";
      shortVersion = release;
      shortVersionedName = "NixOS ${release}";
      supportUrl = "https://nixos.org/nixos/support.html";
      version = version;
      versionedName = ''NixOS ${release} "${codeName}"'';
    };
    style = {
      sidebarBackground = "#4C525D";
      sidebarText = "#FFFFFF";
      sidebarTextHighlight = "#CA9C88";
      sidebarTextSelect = "#292F34";
    };
    welcomeExpandingLogo = false;
    welcomeStyleCalamares = false;
  });

  keyboard-config = writeText "keyboard.conf" (builtins.toJSON {
    writeEtcDefaultKeyboard = false;
    convertedKeymapPath = "${xlibs.xkeyboardconfig}/share/X11/xkb";
  });

  partition-config = writeText "partition.conf" (builtins.toJSON { });

  welcome-config = writeText "welcome.conf" (builtins.toJSON {
    requirements = {
      requiredStorage = 4;
      requiredRam = 0.5;
      check = [ ];
      required = [ ];
    };
  });

  umount-config = writeText "umount.conf" (builtins.toJSON {
    srcLog = "/root/.cache/calamares/session.log";
    destLog = "/var/log/Calamares.log";
  });

  configDir = runCommandNoCC "calamares-config" { } ''
    mkdir -p $out/modules $out/qml $out/branding/nixos
    cp ${config} $out/settings.conf
    cp ${welcome-config}   $out/modules/welcome.conf
    cp ${keyboard-config}  $out/modules/keyboard.conf
    cp ${partition-config} $out/modules/partition.conf
    cp ${umount-config}    $out/modules/umount.conf
    cp ${branding-desc}             $out/branding/nixos/branding.desc
    cp ${./calamares/nixos.png}     $out/branding/nixos/nixos.png
    cp ${./calamares/languages.png} $out/branding/nixos/languages.png
    cp ${./calamares/show.qml}      $out/branding/nixos/show.qml
  '';

  udevsettle = writeShellScriptBin "udevsettle" ''
    ${systemd}/bin/udevadm settle $@
  '';

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
