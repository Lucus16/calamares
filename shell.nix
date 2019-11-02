with { pkgs = import ./nix { }; };
pkgs.mkShell {
  buildInputs = with pkgs; [ niv cacert python python37Packages.ipython ];
}
