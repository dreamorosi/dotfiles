# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

fpath+=($HOME/.zsh/pure)

# ZSH_THEME="refined"
ZSH_THEME=""
autoload -U promptinit; promptinit
prompt pure

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 7

ENABLE_CORRECTION="true"

COMPLETION_WAITING_DOTS="true"

plugins=(
 aws
 git
 gitignore
 fnm
)

source $ZSH/oh-my-zsh.sh

# User configuration

export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nano'
else
   export EDITOR='nano'
fi

# fnm
export PATH="/Users/aamorosi/Library/Application Support/fnm:$PATH"
eval "`fnm env`"