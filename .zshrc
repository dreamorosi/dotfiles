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

# CDK Docker - use finch on macOS
if [[ "$(uname -s)" == "Darwin" ]]; then
  export CDK_DOCKER=finch
fi

# fnm (Node version manager)
case "$(whoami)" in
  andre|aamorosi)
    # macOS: fnm installed via Homebrew
    FNM_PATH="/opt/homebrew/opt/fnm/bin"
    ;;
  ubuntu|ec2-user)
    # Linux: fnm installed to ~/.local/share
    FNM_PATH="$HOME/.local/share/fnm"
    ;;
esac
if [ -n "$FNM_PATH" ] && [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi
if command -v fnm &>/dev/null; then
  eval "$(fnm env --shell zsh)"
fi

# Rust / Cargo
# macOS: rustup is a keg-only Homebrew formula (shims in its own bin).
# Linux: rustup's upstream installer puts shims in ~/.cargo/bin.
if [[ "$(uname -s)" == "Darwin" ]] && [ -d "/opt/homebrew/opt/rustup/bin" ]; then
  export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
elif [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Local binaries
export PATH="$HOME/.local/bin:$PATH"

# OpenCode
export PATH="$HOME/.opencode/bin:$PATH"
export OPENCODE_ENABLE_EXA=true
export OPENCODE_ENABLE_PARALLEL=true
export OPENCODE_EXPERIMENTAL_WORKSPACES=true
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
export OPENCODE_EXPERIMENTAL_LSP_TOOL=true

# Telemetry off
export HOMEBREW_NO_ANALYTICS=1
export SAM_CLI_TELEMETRY=0
export DO_NOT_TRACK=1
export CDK_DISABLE_CLI_TELEMETRY=true
