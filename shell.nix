let

  sources = import ./nix/sources.nix;
  overlays = import ./nix/overlays.nix;

  # Overlays let us override certain packages at a central location.
  nixpkgs = import sources.nixpkgs { };
  nixpkgs-overlayed = import sources.nixpkgs { inherit overlays; };
  hp = nixpkgs-overlayed.haskellPackages;

  contents = import ./nix/contents.nix { inherit nixpkgs; };

  tooling =
    [
      # Haskell tools
      hp.hlint
      hp.fourmolu
      hp.apply-refact
    ];

in hp.shellFor {
  packages = p: map (contents.getPkg p) (builtins.attrNames contents.pkgList);
  buildInputs = tooling;
}
