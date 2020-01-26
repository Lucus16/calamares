#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# === This file is part of Calamares - <https://github.com/calamares> ===
#
#   Copyright 2019, Adriaan de Groot <groot@kde.org>
#
#   Calamares is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Calamares is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Calamares. If not, see <http://www.gnu.org/licenses/>.
"""
=== NixOS Configuration

NixOS has its own "do all the things" configuration file which
declaratively handles what things need to be done in the target
system, and it has an existing tool to "execute" that declarative
specification. This module takes configuration values set by
Calamares viewmodules (e.g. the users module) and puts
them into the configuration file in the target system,
and then runs the necessary NixOS specific tools.
"""

from string import Template
from textwrap import dedent
from time import gmtime, strftime, sleep
import json
import libcalamares
import os
import pathlib
import pprint
import shutil
import subprocess

pp = pprint.PrettyPrinter(depth=6)

import gettext
_ = gettext.translation(
    "calamares-python",
    localedir=libcalamares.utils.gettext_path(),
    languages=libcalamares.utils.gettext_languages(),
    fallback=True).gettext


def pretty_name():
    return _("NixOS Configuration.")


def run():
    """NixOS Configuration."""

    gs = libcalamares.globalstorage

    libcalamares.utils.debug("LocaleDir=" +
                             str(libcalamares.utils.gettext_path()))
    libcalamares.utils.debug("Languages=" +
                             str(libcalamares.utils.gettext_languages()))

    # TODO: probably want to use the job configuration
    #       with a key "stage" to distinguish generate-config
    #       from execute-config; maybe it wants an "all" as well
    #       to do both.
    accumulator = "*** Job configuration\n"
    accumulator += str(libcalamares.job.configuration)
    libcalamares.utils.debug(accumulator)

    accumulator = "*** GlobalStorage configuration\n"
    accumulator += "count: " + str(gs.count()) + "\n"
    libcalamares.utils.debug(accumulator)

    libcalamares.utils.debug("Write nixos configuration.")

    defaultPassword = libcalamares.utils.obscure("foo")
    defaults = {
        "bootLoader": {
            "installPath": "/"
        },
        "localeConf": {
            "LANG": "en_US.UTF-8"
        },
        "password": defaultPassword,
        "rootPassword": defaultPassword,
    }

    for key, value in defaults.items():
        if gs.value(key) == None:
            gs.insert(key, value)

    store = {}

    for key in gs.keys():
        value = gs.value(key)
        libcalamares.utils.debug("{} => {}\n".format(str(key), str(value)))
        store[str(key)] = str(value)

    configuration_nix(gs)
    return

    root = store["rootMountPoint"]

    # libcalamares.job.setprogress( 0.3 )
    # libcalamares.utils.debug("Run nixos-generate-config.")
    # shutil.copyfile("simple.nix", root + "/etc/nixos/configuration.nix")

    libcalamares.job.setprogress(0.1)
    libcalamares.utils.debug("Run nixos-generate-config.")
    subprocess.check_call(["nixos-generate-config", "--root", root],
                          stderr=subprocess.STDOUT)

    libcalamares.job.setprogress(0.2)
    libcalamares.utils.debug("Copying globals.")

    with open(root + "/etc/nixos/globals.json", "w") as f:
        json.dump(store, f)

    libcalamares.job.setprogress(0.3)
    libcalamares.utils.debug("Writing initial config.")
    with open(root + "/etc/nixos/configuration.nix", "w") as f:
        f.write(configuration_nix(gs))

    libcalamares.job.setprogress(0.3)
    libcalamares.utils.debug("Updating channels.")
    subprocess.check_call(["nix-channel", "--update"],
                          stderr=subprocess.STDOUT)

    libcalamares.job.setprogress(0.4)
    libcalamares.utils.debug("Run nixos-install.")
    subprocess.check_call(["nixos-install", "--root", root],
                          stderr=subprocess.STDOUT)

    libcalamares.job.setprogress(1.0)

    # To indicate an error, return a tuple of:
    # (message, detailed-error-message)
    return None


config_template = '''
{ config, pkgs, ... }: {
    imports = [
        ./hardware-configuration.nix
    ];

    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = ${grub_device};

    networking.hostName = ${hostname};
    networking.useDHCP = false;
    networking.interfaces.eth0.useDHCP = true;
    i18n = {
        consoleFont = "Lat2-Terminus16";
        consoleKeyMap = ${console_key_map};
        defaultLocale = ${default_locale};
    };

    time.timeZone = ${timezone};

    environment.systemPackages = with pkgs; [
        wget
        vim
    ];

    sound.enable = true;
    hardware.pulseaudio.enable = true;

    services.xserver = {
        enable = ${enable_x};
        desktopManager.xterm.enable = false;
        ${desktopmanager}
    };

    users.users.${user} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialHashedPassword = ${hashed_pass};
    };

    users.users.root.initialHashedPassword = ${hashed_root_pass};

    system.stateVersion = "19.09";
}
'''


def configuration_nix(gs):
    tmpl = Template(dedent(config_template))
    unformatted = tmpl.substitute(**template_vars(gs))
    print(unformatted)
    print(nixfmt( unformatted ))
    return nixfmt(unformatted)


def template_vars(gs):
    desktopmanager = gs.value("packagechooser_desktopmanager")
    pp.pprint({"dm": desktopmanager})
    if desktopmanager != "":
        desktopmanager = "{}.enable = true;".format(desktopmanager)

    return {
        "timezone": to_nix(timezone(gs)),
        "grub_device": to_nix(gs.value("bootLoader")["installPath"]),
        "hostname": to_nix(gs.value("hostname")),
        "console_key_map": to_nix(gs.value("keyboardLayout")),
        "default_locale": to_nix(gs.value("localeConf")["LANG"]),
        "hashed_pass": to_nix(password_hash(gs.value("password"))),
        "hashed_root_pass": to_nix(password_hash(gs.value("rootPassword"))),
        "user": to_nix(gs.value("username")),
        "desktopmanager": desktopmanager,
        "enable_x": to_nix(desktopmanager != "")
    }


def timezone(gs):
    region = gs.value("locationRegion")
    zone = gs.value("locationZone")
    return "{}/{}".format(region, zone)


def to_nix(v):
    t = type(v)
    if t is bool:
        if t: return "true"
        else: return "false"
    elif v is None:
        return "null"
    elif t is str:
        return "\"{}\"".format(v)
    else:
        print("unknown type {}".format(t))


def nixfmt(v):
    return subprocess.run(["nixfmt"],
                          input=v,
                          encoding='ascii',
                          check=True,
                          stdout=subprocess.PIPE).stdout.strip()


def password_hash(pw):
    return subprocess.run(["mkpasswd", "-m", "sha-512", "-s"],
                          input=libcalamares.utils.obscure(pw),
                          encoding='ascii',
                          check=True,
                          stdout=subprocess.PIPE).stdout.strip()
