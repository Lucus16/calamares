{ sources ? import ./sources.nix }:
with
  { overlay = self: super:
      { inherit (import sources.niv {}) niv;
        packages = self.callPackages ./packages.nix { inherit (self) calamares; };
        calamares = self.libsForQt5.callPackage ./calamares.nix {
          python = self.python3;
          boost = self.boost.override { enablePython = true; python = self.python3; };
        };
      };
  };
import sources.nixpkgs
  { overlays = [ overlay ] ; config = {}; }
