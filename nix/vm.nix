{ config, pkgs, lib, ... }:

{
  environment.systemPackages = [
    (import ./. {}).packages.calamaresWithConfig
  ];

  networking.hostName = "vm";

  i18n = {
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  services.xserver = {
    enable = true;
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = "";

  system.stateVersion = "19.03"; # DO NOT CHANGE
}
