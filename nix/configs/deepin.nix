{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [ wget vim
    vim
    mc
    #gnome3.gnome-terminal
    #gnome3.gedit
    deepin.deepin-menu
    deepin.deepin-terminal
    pcmanfm
    #gnome3.gedit
    firefox
    hicolor-icon-theme
    ######################################
    deepin.dbus-factory
    deepin.dde-api
    deepin.dde-calendar
    deepin.dde-daemon
    #deepin.dde-dock
    #deepin.dde-file-manager
    #deepin.dde-network-utils
    deepin.dde-polkit-agent
    deepin.dde-qt-dbus-factory
    deepin.dde-session-ui
    #deepin.deepin-anything
    deepin.deepin-desktop-base
    deepin.deepin-desktop-schemas
    deepin.deepin-gettext-tools
    deepin.deepin-gtk-theme
    deepin.deepin-icon-theme
    deepin.deepin-image-viewer
    deepin.deepin-menu
    deepin.deepin-metacity
    deepin.deepin-movie-reborn
    deepin.deepin-mutter
    deepin.deepin-shortcut-viewer
    deepin.deepin-sound-theme
    deepin.deepin-terminal
    #deepin.deepin-turbo
    deepin.deepin-wallpapers
    deepin.deepin-wm
    deepin.dpa-ext-gnomekeyring
    deepin.dtkcore
    deepin.dtkwm
    deepin.dtkwidget
    deepin.go-dbus-factory
    deepin.go-dbus-generator
    deepin.go-gir-generator
    deepin.go-lib
    deepin.qt5dxcb-plugin
    deepin.qt5integration
    #deepin.startdde
    #deepin.deepin-screenshot

                                          ];

 services.dbus.packages = with pkgs; [
    gnome3.dconf
    deepin.deepin-menu
  ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  services = {
    xserver = {
      enable = true;
      displayManager.sddm.enable = true;
    };

    deepin = {
      core.enable = true;
      deepin-menu.enable = true;
      deepin-turbo.enable = true;
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword =
      "$6$MTS4u9/0x6L$09nKnUzMXDo9rxn.asZ45.9doQZBW2WEMjmaft1iLLu/js1atyoTkkD1NX.E4J97DCemSGGwqbb5l6YWErsAx0";
  };

  users.users.root.initialHashedPassword =
    "$6$MTS4u9/0x6L$09nKnUzMXDo9rxn.asZ45.9doQZBW2WEMjmaft1iLLu/js1atyoTkkD1NX.E4J97DCemSGGwqbb5l6YWErsAx0";

  system.stateVersion = "19.09";
}
