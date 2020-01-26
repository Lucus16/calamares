{ config, pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    wget
    vim
    lsof
    htop
    (import ../. { }).packages.calamaresWithConfig
  ];

  boot.extraTTYs = [ "tty1" "tty2" "tty3" ];

  virtualisation.memorySize = 1024 * 4;

  users.mutableUsers = false;
  users.users.root.initialPassword = "foo";
  users.users.manveru = {
    initialPassword = "foo";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "19.09";

  services.xserver = {
    enable = true;

    desktopManager.xterm.enable = false;
    # desktopManager.plasma5.enable = true;
    # desktopManager.xfce.enable = true;
    # desktopManager.gnome3.enable = true;
    # desktopManager.mate.enable = true;
    # windowManager.xmonad.enable = true;
    # windowManager.twm.enable = true;
    # windowManager.icewm.enable = true;
    windowManager.i3.enable = true;

    resolutions = lib.mkOverride 9 [{
      x = 1680;
      y = 1050;
    }];
  };
}
