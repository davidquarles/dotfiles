#############
### PATHS ###
#############

# coreutils
export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:$MANPATH
# gnu sed
export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
export MANPATH=/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH
# arcanist / phab
export PATH=$PATH:~/phab/arcanist/bin
# golang
export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin


# Path to your oh-my-zsh installation.
export ZSH=/Users/$(whoami)/.oh-my-zsh
export DEFAULT_USER=$(whoami)

# agnoster, with kubernetes context inject into prompt
ZSH_THEME="dq"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(autopep8 awscli docker encode64 gitfast golang jira kubectl python z)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# aliases
alias d='doctl '
alias dlist='doctl compute droplet list '
alias dsh='doctl compute ssh '
alias gcreds='gcloud container clusters get-credentials '
alias glist='gcloud compute instances list '
alias gobin="curl -F 'gob=<-' http://gobin.io"
alias gsh='gcloud compute ssh '
alias ip='dig +short myip.opendns.com @resolver1.opendns.com'
alias la='ls -a '
alias ll='ls -l '
alias rm='rm -i '
alias trim="sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*\$//g'"
alias watch='watch '

for file in \
	~/.iterm2_shell_integration.bash \
	/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
	[ -f $file ] && . $file
done
export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH

# gcloud
. ~/google-cloud-sdk/path.zsh.inc
. ~/google-cloud-sdk/completion.zsh.inc

# doctl
. <(doctl completion zsh)

# helm
. <(helm completion zsh)

GPG_TTY=$(tty)
export GPG_TTY
export SIGIL_DELIMS={{{,}}}
