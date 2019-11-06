{ writeScriptBin, ckbcomp, makeWrapper, callPackage, calamares, runCommandNoCC
, lib, glibc, xlibs, utillinux, writeText, os-prober, lvm2, writeShellScriptBin
, systemd, xfsprogs, e2fsprogs, coreutils, mkpasswd }:
let
  development = true;

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

    instances = [
      {
        id = "desktopmanager";
        module = "packagechooser";
        config = "desktopmanager.conf";
      }
      {
        id = "package";
        module = "packagechooser";
        config = "package.conf";
      }
    ];

    sequence = if development then [
      {
        show = [
          "welcome"
          "packagechooser@desktopmanager"
          "packagechooser@package"
          "summary"
        ];
      }
      { exec = [ ]; }
      { show = [ "finished" ]; }
    ] else [
      {
        show = [
          "welcome"
          "partition"
          "locale"
          "keyboard"
          "users"
          "packagechooser@desktopmanager"
          "packagechooser@package"
          "summary"
        ];
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
        "https://nixos.org/nixos/manual/release-notes.html#sec-release-${release}";
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
    showSupportUrl = true;
    showKnownIssuesUrl = true;
    showReleaseNotesUrl = true;
    requirements = {
      requiredStorage = 4;
      requiredRam = 2;
      internetCheckUrl = "http://example.com";
      check = if development then [] else [ "storage" "ram" "power" "internet" "root" "screen" ];
      required = if development then [] else [ "storage" "ram" "internet" "screen" "root" "power" ];
    };
  });

  umount-config = writeText "umount.conf" (builtins.toJSON {
    srcLog = "/root/.cache/calamares/session.log";
    destLog = "/var/log/Calamares.log";
  });

  package-config = writeText "windowmanager.conf" (builtins.toJSON {
    labels = { step = "Packages"; };

    id = "packages";
    mode = "optionalmultiple";

    items = [
      {
        id = "bluetooth";
        package = "bluetooth";
        name = "Bluetooth";
        description = ''
          Please pick a desktop environment from the list.
          If you don't want to install a desktop, that's fine, your system will start up in text-only mode and you can install a desktop environment later.
        '';
        screenshot = ":/images/no-selection.png";
      }
      {
        id = "printing";
        package = "printing";
        name = "Printing Support";
        description = ''
          Please pick a desktop environment from the list.
          If you don't want to install a desktop, that's fine, your system will start up in text-only mode and you can install a desktop environment later.
        '';
        screenshot = ":/images/no-selection.png";
      }
    ];
  });

  desktopmanager-config = writeText "desktopmanager.conf" (builtins.toJSON {
    labels = { step = "Desktop"; };

    id = "desktopmanager";
    mode = "optional";

    items = [
      {
        id = "";
        package = "";
        name = "No Desktop";
        description = ''
          Please pick a desktop environment from the list.
          If you don't want to install a desktop, that's fine, your system will start up in text-only mode and you can install a desktop environment later.
        '';
        screenshot = ":/images/no-selection.png";
      }
      {
        id = "gnome";
        package = "gnome";
        name = "Gnome";
        description = ''
          An easy and elegant way to use your computer, GNOME is designed to put
          you in control and get things done.
        '';
        screenshot = ./calamares/gnome.png;
      }
      {
        id = "i3";
        package = "i3";
        name = "i3";
        description = ''
          i3 is a tiling window manager designed for X11, inspired by wmii. It
          supports tiling, stacking, and tabbing layouts, which it handles
          dynamically. Configuration is achieved via plain text file and
          extending i3 is possible using its Unix domain socket and JSON based
          IPC interface from many programming languages.

          i3 uses a control system very similar to vi. By default, window focus
          is controlled by the 'Mod1' (Alt key/Win key) plus the right hand home
          row keys (Mod1+J,K,L,;), while window movement is controlled by the
          addition of the Shift key (Mod1+Shift+J,K,L,;).
        '';
        screenshot = ./calamares/i3.png;
      }
      {
        id = "icewm";
        package = "icewm";
        name = "IceWM";
        description = ''
          IceWM is a window manager for the X Window System. The goal of IceWM
          is speed, simplicity, and not getting in the user's way. It comes with
          a taskbar with pager, global and per-window keybindings and a dynamic
          menu system. Application windows can be managed by keyboard and mouse.
          Windows can be iconified to the taskbar, to the tray, to the desktop
          or be made hidden. They are controllable by a quick switch window
          (Alt+Tab) and in a window list. A handful of configurable focus models
          are menu-selectable. Setups with multiple monitors are supported by
          RandR and Xinerama. IceWM is very configurable, themable and well
          documented. It includes an optional external background wallpaper
          manager with transparency support, a simple session manager and a
          system tray.
        '';
        screenshot = ./calamares/icewm.png;
      }
      {
        id = "kde";
        package = "kde";
        name = "Plasma";
        description = ''
          KDE Plasma Desktop, simple by default, a clean work area for
          real-world usage which intends to stay out of your way. Plasma is
          powerful when needed, enabling the user to create the workflow that
          makes them more effective to complete their tasks.
        '';
        screenshot = ./calamares/plasma.png;
      }
      {
        id = "mate";
        package = "mate";
        name = "MATE";
        description = ''
          The MATE Desktop Environment is the continuation of GNOME 2. It
          provides an intuitive and attractive desktop environment using
          traditional metaphors for Linux and other Unix-like operating systems.
        '';
        screenshot = ./calamares/mate.png;
      }
      {
        id = "twm";
        package = "twm";
        name = "TWM";
        description = ''
          Twm (Tab Window Manager, or sometimes Tom's Window Manager, after the principal
          author Tom LaStrange) provides titlebars, shaped windows, several forms of icon
          management, user-defined macro functions, click-to-type and pointer-driven
          keyboard focus, and user-specified key and pointer button bindings.
        '';
        screenshot = ./calamares/twm.png;
      }
      {
        id = "xfce";
        package = "xfce";
        name = "XFCE";
        description = ''
          Xfce is a lightweight desktop environment for UNIX-like operating
          systems. It aims to be fast and low on system resources, while still
          being visually appealing and user friendly.
        '';
        screenshot = ./calamares/xfce.png;
      }
      {
        id = "xmoand";
        package = "xmonad";
        name = "xmonad";
        description = ''
          Xmonad is a dynamically tiling X11 window manager that is written and
          configured in Haskell. In a normal WM, you spend half your time
          aligning and searching for windows. xmonad makes work easier, by
          automating this.
        '';
        screenshot = ./calamares/xmonad.png;
      }
    ];
  });

  configDir = runCommandNoCC "calamares-config" { } ''
    mkdir -p $out/modules $out/qml $out/branding/nixos
    cp ${config} $out/settings.conf
    cp ${welcome-config} $out/modules/welcome.conf
    cp ${keyboard-config} $out/modules/keyboard.conf
    cp ${partition-config} $out/modules/partition.conf
    cp ${umount-config} $out/modules/umount.conf
    cp ${desktopmanager-config} $out/modules/desktopmanager.conf
    cp ${package-config} $out/modules/package.conf
    cp ${branding-desc} $out/branding/nixos/branding.desc
    cp ${./calamares/nixos.png} $out/branding/nixos/nixos.png
    cp ${./calamares/languages.png} $out/branding/nixos/languages.png
    cp ${./calamares/show.qml} $out/branding/nixos/show.qml
  '';

  udevsettle = writeShellScriptBin "udevsettle" ''
    ${systemd}/bin/udevadm settle $@
  '';
in {
  calamaresWithConfig =
    runCommandNoCC "calamares" { buildInputs = [ makeWrapper ]; } ''
      cp -r ${calamares} $out
      chmod -R u+w $out
      sed -i "s!^Exec=.*!Exec=pkexec $out/bin/calamares!" "$out/share/applications/calamares.desktop"
      wrapProgram $out/bin/calamares \
        --set PATH ${path} \
        --add-flags -c \
        --add-flags ${configDir}
    '';
}
