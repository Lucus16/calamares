with { pkgs = import ./nix { }; };
pkgs.mkShell {
  buildInputs = with pkgs; [
    niv
    cacert
    python3
    python37Packages.ipython
    nixos-rebuild
  ];
}
