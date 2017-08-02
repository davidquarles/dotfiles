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

function pin-to-dock() {
    defaults write com.apple.dock persistent-apps \
        -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/VLC.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    killall Dock
}

function install-homebrew-formula() {

    formulae=(
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
		brew install $uninstalled
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

    brew install gnu-sed --with-default-names
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
        [spotify]=1
        [vagrant]=
        [virtualbox]=
    )

    desired=$(echo ${!casks[*]} | tr " " "\n" | sort -u)
    installed=$(brew cask list | sort -u)
    uninstalled=$(comm -23 <(echo "$desired") <(echo "$installed"))
    if [[ "$uninstalled" != "" ]]; then
		brew cask install $uninstalled
        for cask in ${!casks[*]}; do
            if [ ${docked_casks[$cask]} ]; then
                artifact=$(brew cask info $cask | awk 'found,0;/==> Artifacts/{found=1}' | sed -n 's/ (app)//p')
                [ $artifact ] && dockutil --add "${artifact@E}"
            fi
        done
    fi

}

function install-deps-via-homebrew() {

    install-homebrew-formula
    install-homebrew-casks

    # Remove outdated versions from the cellar.
    brew cleanup
}

function install-docker-for-mac() {
    if ! which docker; then
        # Install docker for mac
        open https://download.docker.com/mac/stable/Docker.dmg
        open ~/Downloads/Docker.dmg
        cp -R /Volumes/Docker/Docker.app /Applications/Docker.app
        open /Applications/Docker.app
        umount /Volumes/Docker
        rm -f ~/Downloads/Docker.dmg
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
        gpg2 --full-generate-key
        gpg --list-secret-keys --keyid-format LONG
        read -p "Enter key ID (not including the encryption scheme prefix, e.g. '9B25A2E0CC62F7UT'" gpg_key_id
        gpg --send-keys $gpg_key_id
    fi
}

function fetch-existing-private-keys() {
    if [ -f ~/Dropbox/creds.tgz.enc ]; then
        gpg -d ~/Dropbox/creds.tgz.enc \
            | tar -C $HOME -xzf -
    fi
}

function install-oh-my-zsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
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

function symlink-dev-dir() {
    ln -snf $HOME/Dropbox/dev $HOME/dev
}

function symlink-dotfiles() {
    dotfiles=$(find $DIR -type f | egrep -v '.*\.sh|.gitmodules|.gitignore|(\.git|usr)/.*')
    for file in $dotfiles; do
        # strip leading $DIR component
        relative_path=${file/$DIR\/}
        target_path=$HOME/$relative_path
        mkdir -p $(dirname $target_path)
        ln -snf $file $target_path
    done
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
    echo "Now we need to manually load/syunc iTerm2 preferences via Dropbox."
    echo "open iTerm2 ->  -> Preferences -> ☑ Load preferences from a custom folder or URL"
    read -p "When complete, press enter to continue" foo
}

function install-gcloud-components() {
    gcloud components list --format=json \
        | jq -r '.[] | select(.state.name != "Installed") | .id' \
        | xargs -n1 gcloud components install
}

function install-gcloud() {
    if ! which gcloud; then
        cd
        url=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-163.0.0-darwin-x86_64.tar.gz
        curl -sL $url | tar -xzf -
        ./google-cloud-sdk/install.sh
        rm -rf google-cloud-sdk*.tar.gz
        source google-cloud-sdk/path.zsh.inc
        source google-cloud-sdk/completion.zsh.inc
        cd -
        exec -l $SHELL
        gcloud init
        install-gcloud-components
    fi

    gcloud components update
}

function install-aws-cli() {
    if ! which aws; then
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        unzip awscli-bundle.zip
        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
        rm -rf awscli*
    fi
}
