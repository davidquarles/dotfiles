#!/usr/bin/env bash
set -euxo pipefail

if [ ! -d ~/dotfiles ]; then
    curl -LJO https://github.com/davidquarles/dotfiles/archive/master.zip
    unzip ~/dotfiles-master.zip
    mv ~/dotfiles-master ~/dotfiles
fi

export DIR=$HOME/dev/dotfiles
. $DIR/utils.sh

# auth + continuous refresh
authenticate-and-wait "$$"

install-osx-updates
install-xcode

setup-homebrew
install-deps-via-homebrew
install-docker-for-mac

# create & set up gpg/ssh
generate-new-private-keys

install-oh-my-zsh
install-powerline
install-gcloud

symlink-dev-dir
symlink-dotfiles
install-vim-pathogen
load-iterm2-preferences
