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
                zsh-history-substring-search labwc wlrctl starship"

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

build_zsh() {
    msg "Build zsh config..."
    install -d "$_D_zsh_confdir" || return 1
    install -m644 config/zsh/starship.plugin.zsh "${_D_zsh_confdir}/starship.plugin.zsh" || return 1
    install -m644 config/zsh/starship.toml "${HOME}/.config/starship.toml" || return 1
    install -m644 config/zsh/zsh-config "${_D_zsh_confdir}/zsh-config" || return 1
    install -m644 config/zsh/zshrc  "${HOME}/.zshrc" || return 1
    msg "...zsh config done."
    return 0
}

# Edit config file(s), and install them
build_labwc() {
    msg "Build Labwc configs..."
    cd labwc || return 1
    install -d "$HOME/.config/labwc" || return 1
    find . -type f -exec install -m644 '{}' "$HOME/.config/labwc/{}" ';'  || return 1
    cd ../config/sfwbar || return 1
    install -d "$HOME/.config/sfwbar" || return 1
    find . -type f -exec install -m644 '{}' "$HOME/.config/sfwbar/{}" ';'  || return 1
    cd ../waybar || return 1
    install -d "$HOME/.config/waybar" || return 1
    find . -type f -exec install -m644 '{}' "$HOME/.config/waybar/{}" ';'  || return 1
    cd ../../scripts || return 1
    install -d "$HOME/bin" || return 1
    find . -type f -exec install -m755 '{}' "$HOME/bin/{}" ';'  || return 1
    msg "...Labwc configs done."
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
    build_labwc ||  die "Install Labwc configs"
    build_rofi ||  die "Install rofi configs"
    build_qttheme ||  die "Install Qt configs"
    build_zsh || die "Install zsh config"
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
