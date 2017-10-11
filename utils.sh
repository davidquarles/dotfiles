#!/usr/bin/env bash

function auth-keepalive() {
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null
}

function authenticate-and-wait() {
    sudo --validate
    auth-keepalive &
}

function install-osx-updates() {
    echo "------------------------------"
    echo "Updating OSX.  If this requires a restart, run the script again."

    # Install all available updates
    sudo softwareupdate -iva

    # Install only recommended available updates
    #sudo softwareupdate -irv
}

function install-xcode() {

    if ! xcode-select -p &>/dev/null; then
        echo "------------------------------"
        echo "Installing Xcode + Command Line Tools.  Choose 'Get Xcode' at prompt"
        xcode-select --install

        echo "Waiting for Xcode command-line tools installation to complete..."
        sp='\|/-'
        delay=${SPINNER_DELAY:-0.15}
        until xcode-select -p &>/dev/null; do
            printf "\b${sp:i++%${#sp}:1}"
            sleep $delay
        done
    fi
}

function setup-homebrew() {
     if test ! $(which brew); then
         echo "Installing homebrew..."
         ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
         brew update
         brew upgrade
     fi
}

function install-homebrew-formula() {

    formulae=(
        awscli
        bash
        coreutils
        dockutil
        doctl
        findutils
        git
        go
        gnupg
        htop
        jq
        kubernetes-helm
        lua
        moreutils
        nmap
        pigz
        pkg-config
        pstree
        pv
        rename
        the_silver_searcher
        watch
        wget
        zsh
        zsh-completions
    )

    desired=$(echo ${formulae[*]} | tr " " "\n" | sort -u)
    installed=$(brew list | sort -u)
    uninstalled=$(comm -23 <(echo "$desired") <(echo "$installed"))
    if [[ "$uninstalled" != "" ]]; then
        brew install $uninstalled || true
    fi

    sudo ln -snf /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

    if [ -f ~/.bashrc ]; then
        cat ~/.bashrc | sed '/^export PATH.*coreutils.*/d' > /tmp/bashrc && mv /tmp/bashrc ~/.bashrc
    fi
    echo "export PATH=$(brew --prefix coreutils)/libexec/gnubin:\$PATH" >> ~/.bashrc

    if [ -f ~/.zshrc ]; then
        cat ~/.zshrc | sed '/^export PATH.*coreutils.*/d' > /tmp/zshrc && mv /tmp/zshrc ~/.zshrc
    fi
    echo "export PATH=$(brew --prefix coreutils)/libexec/gnubin:\$PATH" >> ~/.zshrc

    if ! brew list gnu-sed &>/dev/null; then
        brew install gnu-sed --with-default-names
    fi
}

function install-homebrew-casks() {

    brew tap caskroom/versions

    # value specifies whether to pin to dock
    declare -A casks=(
        [1password]=1
        [dropbox]=
        [google-chrome]=1
        [iterm2]=1
        [java]=
        [skype]=
        [slack]=1
        [spectacle]=
        [spotify]=1
        [vagrant]=
        [virtualbox]=
    )

    desired=$(echo ${!casks[*]} | tr " " "\n" | sort -u)
    installed=$(brew cask list | sort -u)
    uninstalled=$(comm -23 <(echo "$desired" | xargs -n1 | sort -u) <(echo "$installed" | xargs -n1 | sort -u))
    if [[ "$uninstalled" != "" ]]; then
        brew cask install $uninstalled || true
        for cask in ${!casks[*]}; do
            if [ -n ${casks[$cask]} ]; then
                artifact=$(brew cask info $cask | awk 'found,0;/==> Artifacts/{found=1}' | sed -n 's/ (app)//p')
                if [ -n "$artifact" ]; then
                    dockutil --add "/Applications/${artifact@E}"
                fi
            fi
        done
        killall Dock
    fi

}

function install-deps-via-homebrew() {

    install-homebrew-formula

    bash -c "
        set -euxo pipefail
        source $DIR/utils.sh
        install-homebrew-casks
    "

    # Remove outdated versions from the cellar.
    brew cleanup
}

function install-docker-for-mac() {
    if ! which docker; then
        # Install docker for mac
        curl -sL https://download.docker.com/mac/stable/Docker.dmg > /tmp/Docker.dmg
        open -W /tmp/Docker.dmg
        cp -R /Volumes/Docker/Docker.app /Applications/Docker.app
        open /Applications/Docker.app
        umount /Volumes/Docker
        rm -f /tmp/Docker.dmg
    fi
}

function upload-ssh-key-to-github() {
    read -p "Enter github username: " github_username
    curl \
        --user "$github_username" \
        --data '{"title":"test-key","key":"$1"}' \
        https://api.github.com/user/keys
}

function generate-new-private-keys() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen
        upload-ssh-key-to-github "$(gpg --armor --export $gpg_key_id)"
    fi
    if [[ $((ls ~/.gnupg/private-keys-v1.d || true) | wc -l) -eq 0 ]]; then
        gpg --full-generate-key
        gpg --list-secret-keys --keyid-format LONG
        read -p "Enter key ID (not including the encryption scheme prefix, e.g. '9B25A2E0CC62F7UT'" gpg_key_id
        gpg --send-keys $gpg_key_id
    fi
}

function install-oh-my-zsh() {
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
    fi
}

function install-powerline() {
    if ! which pip; then
        sudo easy_install pip
    fi
    if [[ "$(pip list | grep powerline-status)" == "" ]]; then
        pip install --user powerline-status
        rm -rf /tmp/powerline-fonts
        git clone https://github.com/powerline/fonts.git /tmp/powerline-fonts

        set +euo pipefail # this script is brittle :(
        . /tmp/powerline-fonts/install.sh
        set -euo pipefail

        rm -rf /tmp/powerline-fonts
    fi
}

function wait-for-dir() {
    interval=1
    until [ -d "$1" ]; do
        sleep $interval
        interval=$(( interval+1 ))
    done
}

wait-for-git-sync() {
	cd "$1"
	interval=1
    until git diff --exit-code 2>/dev/null; do
        sleep $interval
        interval=$(( interval+1 ))
    done
	cd -
}

function symlink-dev-dir() {
    wait-for-dir $HOME/Dropbox/dev
    ln -snf $HOME/Dropbox/dev $HOME/dev
}

# this assumes `git diff` is a sufficient check
function wait-for-dropbox-sync() {
	wait-for-dir $HOME/dev/dotfiles
	wait-for-git-sync $HOME/dev/dotfiles
}

function symlink-dotfiles() {

    wait-for-dropbox-sync
    dotfiles=$(find $HOME/dev/dotfiles -type f | egrep -v '.*\.sh|.gitmodules|.gitignore|(\.(git|vim)|usr)/.*')
    for file in $dotfiles; do
        # strip leading dirname component
        relative_path=${file/$HOME\/dev\/dotfiles\/}
        target_path=$HOME/$relative_path
        if [ !  -d "$(dirname $target_path)" ]; then
            mkdir -p $(dirname $target_path)
        fi
        # write hard links
        ln -nf $file $target_path
    done

	# symlink .vim -> ~/.vim
	ln -F $HOME/Dropbox/dev/dotfiles/.vim ~/ || true

	# copy from
    for file in $(ls $DIR/usr/local/bin/*); do
        cp $file /usr/local/bin/
    done
}

function install-vim-pathogen() {
    mkdir -p ~/.vim/autoload ~/.vim/bundle
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
}

function load-iterm2-preferences() {
    echo "------------------------------"
    echo "Now we need to manually load/sync iTerm2 preferences via Dropbox."
    echo "open iTerm2 ->  -> Preferences -> ☑ Load preferences from a custom folder or URL"
    read -p "When complete, press enter to continue" foo
}

function install-gcloud-components() {
    gcloud components list --format=json 2>/dev/null \
        | jq -r '.[] | select(.state.name != "Installed") | .id' \
        | xargs gcloud -q components install
}

function install-gcloud() {
    if ! which gcloud; then
        cd
        url=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-163.0.0-darwin-x86_64.tar.gz
        curl -sL $url | tar -xzf -
        zsh ./google-cloud-sdk/install.sh \
            --command-completion=true \
            --path-update=true \
            --quiet \
            --rc-path=$HOME/.zshrc \
            --usage-reporting=true
        rm -rf google-cloud-sdk*.tar.gz
        zsh -c ./google-cloud-sdk/path.zsh.inc
        zsh -c ./google-cloud-sdk/completion.zsh.inc
        cd -
		gcloud init
        install-gcloud-components
    fi

	gcloud -q components update
}

function install-aws-cli() {
    if ! which aws; then
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        unzip awscli-bundle.zip
        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
        rm -rf awscli*
    fi
}
