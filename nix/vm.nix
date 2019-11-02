{ pkgs, config, lib, ... }: {
  networking.hostName = "nixos-installer";

  users = {
    extraUsers.root.initialHashedPassword = "";
    mutableUsers = false;

    motd = with config; ''
      Welcome to ${networking.hostName}

      - This is the Live Installer managed by NixOS
      - All changes are futile

      OS:      NixOS ${system.nixos.release} (${system.nixos.codeName})
      Version: ${system.nixos.version}
      Kernel:  ${boot.kernelPackages.kernel.version}
    '';
  };

  nixpkgs.pkgs = import ./. { };

  environment.systemPackages = with pkgs; [
    (import ./. {}).packages.calamaresWithConfig
    vim
    # pkgs.packages.calamaresWithConfig
    strace
    tmux
    tree
    htop
    links
    xorg.xeyes
    xterm
  ];

  services.nscd.enable = false;
  boot.extraTTYs = [
    "tty2"
  ];

  environment.pathsToLink = [ "/libexec" ];

  services.xserver = {
    enable = true;
    desktopManager = {
      default = "i3";
      xterm.enable = false;
    };

    resolutions = lib.mkOverride 9 [ { x = 1680; y = 1050; } ];

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ dmenu i3status ];
      configFile = pkgs.writeText "i3.config" ''
        exec --no-startup-id calamares -d > /installation.log
        bindsym Mod1+Return exec ${pkgs.xterm}/bin/xterm
      '';
    };

    displayManager.auto = {
      enable = true;
      user = "root";
    };
    displayManager.lightdm.enable = true;
  };

  virtualisation.memorySize = 2048;
  virtualisation.emptyDiskImages = [
    5000
  ];
}
