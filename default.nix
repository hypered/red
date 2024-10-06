let
  sources = import ./nix/sources.nix;
  overlays = import ./nix/overlays.nix;
  pkgs = import sources.nixpkgs { inherit overlays; };
  modules = import "${sources.home-manager}/modules/default.nix" {
    inherit pkgs;
    configuration = ./home-manager-configuration.nix;
  };

  neovim-bin = modules.config.programs.neovim.finalPackage;
in rec
{
  # Build with nix-build -A <attr>

  # A configuration file for nvim.
  neovim-config = pkgs.writeText "init.vim"
    modules.config.programs.neovim.generatedConfigViml;

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

  # A shell to try out our binaries
  # Run with nix-shell default.nix -A shell
  shell = pkgs.mkShell {
    buildInputs = [
      binaries
      neovim-bin
    ];
    shellHook = ''
      source <(red --bash-completion-script `which red`)
      export RED_NEOVIM_BIN=${neovim-bin}/bin/nvim
      export RED_NEOVIM_CONF=${neovim-config}
    '';
  };
}
