{ pkgs, config, lib, ... }: {
  # networking.hostName = "nixos-installer";

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
    (import ./. { }).packages.calamaresWithConfig
    strace
    tmux
    tree
    htop
    xorg.xeyes
    xterm
    kate
  ];

  boot.extraTTYs = [ "tty2" ];

  services.xserver.resolutions = lib.mkOverride 9 [{
    x = 1680;
    y = 1050;
  }];

  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix>
  ];

  services.xserver = {
    desktopManager.plasma5 = {
      enable = true;
      enableQt4Support = false;
    };
  };

  system.activationScripts.installerDesktop = let

    # Comes from documentation.nix when xserver and nixos.enable are true.
    manualDesktopFile =
      "/run/current-system/sw/share/applications/nixos-manual.desktop";

    homeDir = "/home/nixos/";
    desktopDir = homeDir + "Desktop/";

  in ''
    mkdir -p ${desktopDir}
    chown nixos ${homeDir} ${desktopDir}

    ln -sfT ${manualDesktopFile} ${desktopDir + "nixos-manual.desktop"}
    ln -sfT ${pkgs.gparted}/share/applications/gparted.desktop ${
      desktopDir + "gparted.desktop"
    }
    ln -sfT ${pkgs.konsole}/share/applications/org.kde.konsole.desktop ${
      desktopDir + "org.kde.konsole.desktop"
    }
  '';

}
