#!/usr/bin/env bash
set -euxo pipefail

ARGS="$@"

if [ ! -d ~/dotfiles ]; then
    curl -LJO https://github.com/davidquarles/dotfiles/archive/master.zip
    unzip ~/dotfiles-master.zip
    mv ~/dotfiles-master ~/dotfiles
fi

export DIR=$HOME/dotfiles
. $DIR/utils.sh

# auth + continuous refresh
authenticate-and-wait "$$"

$ARGS

exec /usr/bin/env zsh
