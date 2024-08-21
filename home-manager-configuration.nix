{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      (nvim-treesitter.withPlugins(p: [
        p.bash
        p.haskell
        p.json
        p.lua
        p.markdown
        p.nix
        p.python
        p.rust
        p.zig
        p.vimdoc
      ]))
      conform-nvim
      neogit
      fzf-vim
    ];
    extraConfig = ''
      " For faster startup
      lua vim.loader.enable()

      " General
      set nocompatible            " get rid of Vi compatibility mode. SET FIRST!
      filetype plugin indent on   " filetype detection[ON] plugin[ON] indent[ON]

      " Tabs/spaces
      set tabstop=2
      set expandtab
      set shiftwidth=2

      " Navigation
      set scrolloff=3             " some lines around scroll for context

      " Cursor/Line
      " set number
      set colorcolumn=-0          " based on textwidth
      " set cursorline              " highlight the current line

      " Status/History
      set history=200             " remember a lot of stuff
      set ruler                   " Always show info along bottom.
      set cmdheight=1

      " Scrolling
      set ttyfast

      " Files
      set autoread                            " auto-reload files changed on disk
      set updatecount=0                       " disable swap files
      set wildmode=longest,list,full 

      " Vimdiff
      set diffopt=filler,vertical

      " Conceal (disabled by default)
      set conceallevel=0

      " Wrapping
      " set nowrap

      " Leader
      nnoremap <Space> <Nop>
      let mapleader = ' '
      let maplocalleader = ' '

      " Make F1 work like Escape.
      map <F1> <Esc>
      imap <F1> <Esc>

      " Mouse issue (https://github.com/neovim/neovim/wiki/Following-HEAD#20170403)
      set mouse=a

      " Use system clipboard for yanks.
      set clipboard+=unnamedplus

      " Use ,t for 'jump to tag'.
      nnoremap <Leader>t <C-]>

      " Allow hidden windows
      set hidden

      " Grep with rg
      set grepprg=rg\ --line-number\ --column
      set grepformat=%f:%l:%c:%m

      " Theme
      set notermguicolors
      set bg=light
      colorscheme wildcharm                                  " Start with wildcharm
      hi Normal ctermfg=black ctermbg=white cterm=NONE       " Code
      hi Comment ctermfg=darkgrey ctermbg=NONE cterm=NONE    " Comments
      hi PreProc ctermfg=darkmagenta ctermbg=NONE cterm=NONE " import qualified as
      hi Type ctermfg=darkred ctermbg=NONE cterm=NONE        " module where data
      hi Statement ctermfg=darkred ctermbg=NONE cterm=NONE   " operators
      hi String ctermfg=darkblue ctermbg=NONE cterm=NONE     " string literals
      hi Constant ctermfg=darkblue ctermbg=NONE cterm=NONE   " characters
      hi Todo ctermfg=black ctermbg=yellow cterm=NONE
      hi Visual ctermfg=lightgray ctermbg=black cterm=reverse

      syntax enable               " enable syntax highlighting
    '';
  };

  # Make home-manager happy.
  home.username = "thu";
  home.homeDirectory = "/tmp";
  home.stateVersion = "24.05";
}
