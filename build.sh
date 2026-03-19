#!/bin/sh
# Install script to Labwc-mod

_D_debug="0"
_D_update="0"
_D_zsh_confdir="$HOME/.config/zsh.d"
_D_basedir=$(pwd)
_D_patchdir="${_D_basedir}/patches"
_D_NetBSD_deps="linux-libertine-ttf zsh zsh-autosuggestions zsh-syntax-highlighting \
                zsh-completions breeze-icons rofi nerd-fonts-Meslo cmake gmake \
                wget binutils perl consolekit keepassxc gnome-keyring \
                libsecret quasselclient qt5ct qt6ct alacritty swaybg swayidle swaylock \
                zsh-history-substring-search labwc"

# Read arguments
for _arg in "$@"; do
    case "$_arg" in
        -d)
            _D_debug="1"
            ;;
        -u)
            _D_update="1"
            ;;
        -U)
            _D_update="2"
            ;;
        -h)
            _D_debug="2"
            ;;
    esac
done

# Small functions
msg() {
    echo ">>> $*"
}

die () {
    _errc=$?
    if [ -n "$1" ]; then
        echo ">>> $1 failed ($_errc)"
    fi
    exit $_errc
}

patching() {
    for _patch in "$_D_patchdir"/"$1"/*.patch; do
        if [ -e "$_patch" ]; then
            patch -Np1 -i "$_patch" || return 1
        fi
    done
    for _patchn in "$_D_patchdir"/netbsd/"$1"/*.patch; do
        if [ -e "$_patchn" ]; then
            if [ "$1" = "system" ]; then
                sudo patch -Np1 -i "$_patchn" || return 1
            else
                patch -Np1 -i "$_patchn" || return 1
            fi
        fi
    done
    return 0
}

cleaning() {
    msg "Clean build directory..."
    cd "$_D_basedir" || return 1
    rm -rf external || return 1
    return 0
}

# Install dependencies from binary repository
install_deps() {
    sudo pkgin install $_D_NetBSD_deps || return 1
    return 0
}

# manjaro-zsh-config
# https://gitlab.manjaro.org/packages/community/manjaro-zsh-config/-/blob/master/PKGBUILD
# https://github.com/Chrysostomus/manjaro-zsh-config
# DEPS: zsh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search
#       zsh-completions ttf-meslo-nerd-font-powerlevel10k zsh-theme-powerlevel10k
build_mzc() {
    msg "Build manjaro-zsh-config..."
    cd external || return 1
    git clone https://github.com/Chrysostomus/manjaro-zsh-config || return 1
    cd manjaro-zsh-config || return 1
    patching manjaro-zsh-config || return 1
    install -d "$_D_zsh_confdir" || return 1
    install -m644 .zshrc  "${HOME}/.zshrc" || return 1
    install -m644 manjaro-zsh-config "${_D_zsh_confdir}/manjaro-zsh-config" || return 1
    install -m644 manjaro-zsh-prompt "${_D_zsh_confdir}/manjaro-zsh-prompt" || return 1
    install -m644 p10k.zsh "${_D_zsh_confdir}/p10k.zsh" || return 1
    install -m644 p10k-portable.zsh "${_D_zsh_confdir}/p10k-portable.zsh" || return 1
    msg "...manjaro-zsh-config done."
    cd "$_D_basedir" || return 1
    return 0
}

# zsh-theme-powerlevel10k
# https://github.com/romkatv/powerlevel10k
# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=zsh-theme-powerlevel10k-git
build_p10k() {
    msg "Build powerlevel10k theme..."
    cd external || return 1
    git clone https://github.com/romkatv/powerlevel10k || return 1
    cd powerlevel10k/gitstatus || return 1
    sed -i'' '/gitstatus_cxx=clang++12/d' build  || return 1
    ./build -w  || return 1
    # go to ./build/powerlevel10k
    cd ..
    rm -rf  .git
    rm -rf gitstatus/src  || return 1
    rm -rf gitstatus/deps  || return 1
    rm -rf gitstatus/.vscode  || return 1
    install -d "${_D_zsh_confdir}/zsh-theme-powerlevel10k/config"  || return 1
    install -d "${_D_zsh_confdir}/zsh-theme-powerlevel10k/internal"  || return 1
    install -d "${_D_zsh_confdir}/zsh-theme-powerlevel10k/gitstatus/usrbin"  || return 1
    install -d "${_D_zsh_confdir}/zsh-theme-powerlevel10k/gitstatus/docs"  || return 1
    find . -type f -exec install '{}' "${_D_zsh_confdir}/zsh-theme-powerlevel10k/{}" ';'  || return 1
    make -C "${_D_zsh_confdir}/zsh-theme-powerlevel10k" minify  || return 1
    cd "${_D_zsh_confdir}/zsh-theme-powerlevel10k" || return 1
    for file in *.zsh-theme internal/*.zsh gitstatus/*.zsh gitstatus/install; do
        zsh -fc "emulate zsh -o no_aliases && zcompile -R -- $file.zwc $file"  || return 1
    done
    msg "...powerlevel10k theme done."
    cd "$_D_basedir" || return 1
    return 0
}

# Edit config file(s), and install them
#TODO
build_fluxbox() {
    msg "Build fluxbox configs..."
    cd fluxbox || return 1
    install -d "$HOME/.fluxbox/styles/kikadf/pixmaps" || return 1
    install -d "$HOME/.fluxbox/backgrounds" || return 1
    install -d "$HOME/.fluxbox/scripts" || return 1
    find . -type f -exec install -m644 '{}' "$HOME/.fluxbox/{}" ';'  || return 1
    sed -i "s|@OSNAME@|$_D_os|" "$HOME/.fluxbox/menu"
    chmod 755 "$HOME"/.fluxbox/scripts/*
    msg "...fluxbox configs done."
    cd "$_D_basedir" || return 1
    return 0
}

# Rofi config
build_rofi() {
    msg "Build rofi configs..."
    cd config/rofi || return 1
    install -d "$HOME/.config/rofi" || return 1
    find . -type f -exec install -m644 '{}' "$HOME/.config/rofi/{}" ';'  || return 1
    msg "...rofi configs done."
    cd "$_D_basedir" || return 1
    return 0
}

# Install Qt configs
build_qttheme() {
    msg "Build Qt configs..."
    cd external || return 1
    git clone https://github.com/catppuccin/qt5ct.git || return 1
    cp -Rf ../config/qt5ct "$HOME/.config/" || return 1
    mkdir -p "$HOME/.config/qt5ct/colors/" || return 1
    cp -f qt5ct/themes/*.conf "$HOME/.config/qt5ct/colors/" || return 1
    cp -Rf ../config/qt6ct "$HOME/.config/" || return 1
    mkdir -p "$HOME/.config/qt6ct/colors/" || return 1
    cp -f qt5ct/themes/*.conf "$HOME/.config/qt6ct/colors/" || return 1
    msg "...Qt configs done."
    cd "$_D_basedir" || return 1
    return 0
}

# Fix groups to enable user shutdown/reboot
add_groups() {
    sudo usermod -G operator "$USER" || return 1
    msg "...group changes done."
    return 0
}

# Set default shell
set_zsh() {
    msg "Set zsh to default shell"
    chpass -s zsh || return 1
    return 0
}

# Set autologin and autostart X
#TODO
set_autostart() {
    install -m644 config/zsh/zprofile.in "${HOME}/.zprofile" || return 1
    cd /etc || return 1
    # gettytab, ttys
    patching system || return 1
    cd "$_D_basedir" || return 1
    return 0
}

# Help
help() {
    echo "Usage: build.sh [-u|-U|-h|-d]"
    echo ""
    echo "  -d      Don't clean external build directory after build"
    echo "  -u      Don't install dependencies"
    echo "  -U      Don't install system config files"
    echo "  -h      Show this help"
    echo ""
    echo "  Without arg make full build, install dependencies, install"
    echo "  config files, build and install zsh stuff, clean build dir."
}

# Work
main() {
    mkdir external
    if [ $_D_update -lt 2 ]; then
        msg "Start build and install Labwc-mod:"
        if [ $_D_update -eq 0 ]; then
            msg "Install dependencies:"
            install_deps || die "Installing dependencies"
        fi
        add_groups ||  die "Set user groups"
        set_zsh || die "Set zsh to default shell"
        set_autostart || die "Set autostart/login"
    else
        msg "Update Labwc-mod:"
    fi
    #TODO
    build_fluxbox ||  die "Install fluxbox configs"
    build_rofi ||  die "Install rofi configs"
    build_qttheme ||  die "Install Qt configs"
    build_mzc || die "Building mozilla-zsh-config"
    build_p10k || die "Building powerlevel10k theme"
    if [ $_D_debug -eq 0 ]; then
        cleaning || die "Cleaning"
        msg "Ready."
    else
        msg "Finished without cleaning."
    fi
}

if [ $_D_debug -eq 2 ]; then
    help
else
    main
fi

exit 0
