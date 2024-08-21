let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  modules = import "${sources.home-manager}/modules/default.nix" {
    inherit pkgs;
    configuration = ./home-manager-configuration.nix;
  };

  neovim-bin = modules.config.programs.neovim.finalPackage;
  neovim-config = pkgs.writeText "init.vim"
    modules.config.programs.neovim.generatedConfigViml;
in
{
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
}
