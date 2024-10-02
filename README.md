# Red

This is just a Neovim configuration that can be reused (in particular, in
`hypered/design` and in `hypered/slab`).

In practice, the `nvim` program is wrapped with some specific arguments and
configuration files. Those are described using Nix, through `home-manager`'s
support, but it is not necessary to use `home-manager` to use this repository's
derivation.

```
$ nix-build --attr neovim
$ result/bin/nvim
```

In addition of `nvim`, there is also a derivation to produce a `highlight`
script. It generates a syntax-highlighted version of a piece of code using
HTML. This uses the same configuration as above for consistency.

```
$ nix-build --attr highlight
$ result/bin/highlight input.hs
$ cat input.hs.html
```

There is also a `red` binary. It is currently doing nothing, but in the future,
it should do the same as `highlight` with some post-processing (mainly to
output just the HTML code corresponding to the highlighted code, instead of a
complete standalone HTML document).
