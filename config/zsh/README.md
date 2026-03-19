# bsd-zsh-config
Zsh config to BSDs

### Internal dependencies:
- [manjaro-zsh-config](https://github.com/Chrysostomus/manjaro-zsh-config)
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)

### Dependencies:
- cmake (build)
- gmake (build)
- wget (build)
- binutils (build)
- perl5 (build)
- zsh
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- nerd-fonts
- pkg-provides

### Build:

`$ git clone https://github.com/kikadf/bsd-zsh-config`

`$ cd bsd-zsh-config`

`$ ./build.sh`

Internal dependencies install to the `~/.config/zsh.d/` directory.
