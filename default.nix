let
  sources = import ./nix/sources.nix;
  overlays = import ./nix/overlays.nix;
  pkgs = import sources.nixpkgs { inherit overlays; };
  modules = import "${sources.home-manager}/modules/default.nix" {
    inherit pkgs;
    configuration = ./home-manager-configuration.nix;
  };

  neovim-bin = modules.config.programs.neovim.finalPackage;
  neovim-config = pkgs.writeText "init.vim"
    modules.config.programs.neovim.generatedConfigViml;
in
{
  # Build with nix-build -A <attr>

  # A configured version of nvim.
  neovim = pkgs.writeScriptBin "nvim" ''
    ${neovim-bin}/bin/nvim \
      -u ${neovim-config} \
      "$@"
  '';

  # A script to convert a file to HTML, using nvim syntax highlighting.
  highlight = pkgs.writeScriptBin "highlight" ''
    set -e
    INPUT_FILE=$1

    if [ ! -f "$INPUT_FILE" ]; then
      echo "Error: File does not exist: $INPUT_FILE"
      exit 1
    fi

    ${neovim-bin}/bin/nvim \
      --clean\
      -es \
      -u ${neovim-config} \
      -i NONE \
      -c "set columns=90" \
      -c "TOhtml" \
      -c "w! $INPUT_FILE.html" \
      -c "qa!" "$INPUT_FILE" \
      > /dev/null
  '';

  # Same as `highlight`, with some post-processing applied.
  binaries = pkgs.haskellPackages.red;
  haddock = pkgs.haskellPackages.red.doc;
}
