#!/usr/bin/env bash

set -e

# =============================================================================
# Dotfiles Bootstrap Script
# Cross-platform setup for macOS and Linux
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*) OS="macos" ;;
        Linux*)  OS="linux" ;;
        *)       error "Unsupported OS: $(uname -s)" ;;
    esac
    info "Detected OS: $OS"
}

# Detect package manager
detect_package_manager() {
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &>/dev/null; then
            PKG_MANAGER="brew"
        else
            warn "Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            PKG_MANAGER="brew"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if command -v apt-get &>/dev/null; then
            PKG_MANAGER="apt"
        elif command -v dnf &>/dev/null; then
            PKG_MANAGER="dnf"
        elif command -v yum &>/dev/null; then
            PKG_MANAGER="yum"
        elif command -v pacman &>/dev/null; then
            PKG_MANAGER="pacman"
        else
            error "No supported package manager found (apt, dnf, yum, pacman)"
        fi
    fi
    info "Using package manager: $PKG_MANAGER"
}

# Install a package cross-platform
install_package() {
    local pkg="$1"
    info "Installing $pkg..."
    case "$PKG_MANAGER" in
        brew)   brew install "$pkg" ;;
        apt)    sudo apt-get install -y "$pkg" ;;
        dnf)    sudo dnf install -y "$pkg" ;;
        yum)    sudo yum install -y "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
    esac
}

# Check if command exists
has_command() {
    command -v "$1" &>/dev/null
}

# =============================================================================
# Secrets Check
# =============================================================================

check_secrets() {
    local dotfiles_source
    dotfiles_source="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    local secrets_template="$dotfiles_source/secrets.template"
    local secrets_env="$dotfiles_source/secrets.env"

    # Check if any secrets are set
    if [[ -z "${WAKATIME_API_KEY:-}" ]] && [[ -z "${OPENCODE_BEDROCK_API_KEY:-}" ]]; then
        warn "No secrets found in environment!"
        echo ""
        echo "To configure secrets:"
        echo "  1. Copy the template:  cp secrets.template secrets.env"
        echo "  2. Edit with your keys: \$EDITOR secrets.env"
        echo "  3. Source and rerun:   source secrets.env && ./bootstrap.sh"
        echo ""
        
        # Check if secrets.env exists but wasn't sourced
        if [[ -f "$secrets_env" ]]; then
            warn "secrets.env exists but wasn't sourced!"
            echo "  Run: source secrets.env && ./bootstrap.sh"
        elif [[ -f "$secrets_template" ]]; then
            echo "  Or run without secrets (you can configure them later)"
        fi
        
        echo ""
        read -p "Continue without secrets? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Exiting. Run again after sourcing secrets.env"
            exit 0
        fi
    fi
}

# =============================================================================
# Setup Functions
# =============================================================================

setup_zsh() {
    if ! has_command zsh; then
        install_package zsh
    fi

    # Install oh-my-zsh if not present
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        info "oh-my-zsh already installed, skipping..."
    fi

    # Install pure prompt
    if [[ ! -d "$HOME/.zsh/pure" ]]; then
        info "Installing pure prompt..."
        mkdir -p "$HOME/.zsh"
        git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
    else
        info "pure prompt already installed, skipping..."
    fi

    # Set zsh as default shell on Linux
    if [[ "$OS" == "linux" ]]; then
        local current_shell
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        local zsh_path
        zsh_path=$(which zsh)
        
        if [[ "$current_shell" != "$zsh_path" ]]; then
            info "Setting zsh as default shell..."
            if has_command chsh; then
                chsh -s "$zsh_path" || {
                    warn "Failed to change shell. You may need to run manually:"
                    echo "  chsh -s $zsh_path"
                }
            else
                warn "chsh not available. Add zsh to /etc/shells and run:"
                echo "  chsh -s $zsh_path"
            fi
        fi
    fi
}

setup_fnm() {
    if ! has_command fnm; then
        info "Installing fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    else
        info "fnm already installed, skipping..."
    fi
}

setup_neovim() {
    if ! has_command nvim; then
        info "Installing neovim..."
        case "$PKG_MANAGER" in
            brew)   brew install neovim ;;
            apt)    
                # Use latest stable from PPA on Ubuntu/Debian
                if has_command add-apt-repository; then
                    sudo add-apt-repository -y ppa:neovim-ppa/stable
                    sudo apt-get update
                fi
                sudo apt-get install -y neovim
                ;;
            dnf)    sudo dnf install -y neovim ;;
            yum)
                # Amazon Linux - install from EPEL or download AppImage
                if ! yum list installed epel-release &>/dev/null; then
                    sudo yum install -y epel-release || true
                fi
                if yum list available neovim &>/dev/null; then
                    sudo yum install -y neovim
                else
                    warn "Neovim not in yum repos, installing via AppImage..."
                    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                    chmod u+x nvim.appimage
                    sudo mv nvim.appimage /usr/local/bin/nvim
                fi
                ;;
            pacman) sudo pacman -S --noconfirm neovim ;;
        esac
    else
        info "neovim already installed, skipping..."
    fi
}

setup_gh() {
    if ! has_command gh; then
        info "Installing GitHub CLI..."
        case "$PKG_MANAGER" in
            brew)   brew install gh ;;
            apt)
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y gh
                ;;
            dnf)    sudo dnf install -y gh ;;
            yum)
                # Amazon Linux
                sudo yum install -y yum-utils || true
                sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                sudo yum install -y gh
                ;;
            pacman) sudo pacman -S --noconfirm github-cli ;;
        esac
    else
        info "GitHub CLI already installed, skipping..."
    fi
}

setup_container_runtime() {
    if [[ "$OS" == "macos" ]]; then
        # Install Finch on macOS
        if ! has_command finch; then
            info "Installing Finch (container runtime for macOS)..."
            brew install --cask finch
            info "Initializing Finch VM..."
            finch vm init || true
        else
            info "Finch already installed, skipping..."
        fi
    else
        # Install Docker in rootless mode on Linux
        if ! has_command docker; then
            info "Installing Docker in rootless mode..."
            
            # Install dependencies
            case "$PKG_MANAGER" in
                apt)
                    sudo apt-get update
                    sudo apt-get install -y uidmap dbus-user-session fuse-overlayfs slirp4netns
                    ;;
                dnf)
                    sudo dnf install -y shadow-utils fuse-overlayfs slirp4netns
                    ;;
                yum)
                    sudo yum install -y shadow-utils fuse-overlayfs slirp4netns
                    ;;
                pacman)
                    sudo pacman -S --noconfirm fuse-overlayfs slirp4netns
                    ;;
            esac
            
            # Install Docker using official script
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
            
            # Setup rootless mode
            info "Setting up Docker rootless mode..."
            dockerd-rootless-setuptool.sh install || {
                warn "Rootless setup failed. You may need to run manually:"
                echo "  dockerd-rootless-setuptool.sh install"
            }
            
            # Add to systemd user services
            systemctl --user start docker || true
            systemctl --user enable docker || true
            
            info "Docker rootless mode configured"
            warn "You may need to log out and back in for changes to take effect"
        else
            info "Docker already installed, skipping..."
            # Check if running rootless
            if docker info 2>/dev/null | grep -q "rootless"; then
                info "Docker is running in rootless mode"
            else
                warn "Docker is installed but NOT in rootless mode"
                warn "Consider reinstalling with rootless mode for security"
            fi
        fi
    fi
}

setup_brew_bundle() {
    # macOS only: install everything declared in the Brewfile.
    if [[ "$OS" != "macos" ]]; then
        return
    fi
    if ! has_command brew; then
        warn "Homebrew not found, skipping brew bundle"
        return
    fi

    local dotfiles_source
    dotfiles_source="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    local brewfile="$dotfiles_source/Brewfile"

    if [[ ! -f "$brewfile" ]]; then
        warn "Brewfile not found at $brewfile, skipping"
        return
    fi

    info "Installing packages from Brewfile (brew bundle)..."
    brew bundle --file="$brewfile" || warn "brew bundle reported errors (continuing)"
}

setup_opencode() {
    if ! has_command opencode; then
        info "Installing OpenCode..."
        curl -fsSL https://opencode.ai/install | bash
    else
        info "OpenCode already installed, skipping..."
    fi
}

setup_wakatime() {
    if [[ -n "${WAKATIME_API_KEY:-}" ]]; then
        info "Configuring WakaTime..."
        printf "[settings]\napi_key = %s\n" "$WAKATIME_API_KEY" > ~/.wakatime.cfg
    else
        warn "WAKATIME_API_KEY not set, skipping WakaTime config"
        warn "Set it later in ~/.wakatime.cfg"
    fi
}

setup_opencode_secrets() {
    local config_file="$HOME/.config/opencode/opencode.json"
    if [[ -n "${OPENCODE_BEDROCK_API_KEY:-}" ]] && [[ -f "$config_file" ]]; then
        info "Configuring OpenCode Bedrock API key..."
        # If the file is a symlink into the dotfiles repo, replace it with a
        # real copy first so the injected secret never lands in the repo.
        if [[ -L "$config_file" ]]; then
            local real
            real="$(cat "$config_file")"
            rm "$config_file"
            printf '%s' "$real" > "$config_file"
        fi
        if [[ "$OS" == "macos" ]]; then
            sed -i '' "s|\"apiKey\": \"\"|\"apiKey\": \"$OPENCODE_BEDROCK_API_KEY\"|" "$config_file"
        else
            sed -i "s|\"apiKey\": \"\"|\"apiKey\": \"$OPENCODE_BEDROCK_API_KEY\"|" "$config_file"
        fi
    else
        warn "OPENCODE_BEDROCK_API_KEY not set or config missing, skipping..."
    fi
}

setup_claude_secrets() {
    # Claude Code reads the Bedrock token from settings.json env. We keep the
    # token out of the repo (committed value is ""), reusing the same secret
    # as OpenCode (OPENCODE_BEDROCK_API_KEY).
    local config_file="$HOME/.claude/settings.json"
    if [[ -n "${OPENCODE_BEDROCK_API_KEY:-}" ]] && [[ -f "$config_file" ]]; then
        info "Configuring Claude Code Bedrock token..."
        # Break the symlink into the repo before injecting the secret.
        if [[ -L "$config_file" ]]; then
            local real
            real="$(cat "$config_file")"
            rm "$config_file"
            printf '%s' "$real" > "$config_file"
        fi
        if [[ "$OS" == "macos" ]]; then
            sed -i '' "s|\"AWS_BEARER_TOKEN_BEDROCK\": \"\"|\"AWS_BEARER_TOKEN_BEDROCK\": \"$OPENCODE_BEDROCK_API_KEY\"|" "$config_file"
        else
            sed -i "s|\"AWS_BEARER_TOKEN_BEDROCK\": \"\"|\"AWS_BEARER_TOKEN_BEDROCK\": \"$OPENCODE_BEDROCK_API_KEY\"|" "$config_file"
        fi
    else
        warn "OPENCODE_BEDROCK_API_KEY not set or Claude settings missing, skipping..."
    fi
}

setup_signing() {
    # Git commit signing uses the SSH key at ~/.ssh/github (see .gitconfig
    # and .ssh/config). The public key + allowed_signers are needed for
    # signing and local verification.
    local priv="$HOME/.ssh/github"
    local pub="$HOME/.ssh/github.pub"

    if [[ ! -f "$priv" ]]; then
        warn "SSH signing key $priv not found, skipping signing setup"
        warn "Add your GitHub SSH key to $priv, then re-run, or generate one with:"
        echo "  ssh-keygen -t ed25519 -C \"dreamorosi@gmail.com\" -f $priv"
        return
    fi

    # Derive the public key from the private key if it's missing
    if [[ ! -f "$pub" ]]; then
        info "Deriving $pub from private key..."
        ssh-keygen -y -f "$priv" > "$pub"
        chmod 644 "$pub"
    fi

    info "Commit signing configured (key: $pub)"
    warn "Remember to add this key to GitHub as a SIGNING key for the Verified badge:"
    echo "  https://github.com/settings/ssh/new (Key type: Signing Key)"
}

setup_ssh_include() {
    # Compose ~/.ssh/config from fragments so the dotfile-managed hosts
    # (~/.ssh/config.d/*.conf, symlinked from this repo) coexist with
    # machine-managed configs (e.g. Amazon WSSH writes into ~/.ssh/config).
    local ssh_config="$HOME/.ssh/config"
    local include_line="Include config.d/*.conf"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ ! -f "$ssh_config" ]]; then
        info "Creating $ssh_config with dotfiles Include..."
        printf '%s\n' "$include_line" > "$ssh_config"
        chmod 600 "$ssh_config"
        return
    fi

    if grep -qF "$include_line" "$ssh_config"; then
        info "ssh config Include already present, skipping..."
        return
    fi

    # Prepend the Include so dotfile hosts win first-match resolution.
    info "Injecting Include line at top of $ssh_config..."
    local tmp
    tmp="$(mktemp)"
    printf '%s\n\n' "$include_line" > "$tmp"
    cat "$ssh_config" >> "$tmp"
    cat "$tmp" > "$ssh_config"
    rm -f "$tmp"
    chmod 600 "$ssh_config"
}

# =============================================================================
# Symlink Dotfiles
# =============================================================================

symlink_dotfiles() {
    info "Symlinking dotfiles..."
    
    local dotfiles_source
    dotfiles_source="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    
    # Files/dirs to skip
    local -a deny_list=(
        "bootstrap.sh"
        "secrets.template"
        "secrets.env"
        "README.md"
        "LICENSE"
        "Brewfile"
        ".git"
        ".gitignore"
        # ~/.ssh/config is composed via Include (see setup_ssh_include) so it
        # can coexist with machine-managed configs (e.g. Amazon WSSH). Never
        # symlink over it.
        ".ssh/config"
    )

    while IFS= read -r file; do
        local skip=false
        local relative_path="${file#"$dotfiles_source"/}"
        
        # Check deny list
        for item in "${deny_list[@]}"; do
            if [[ "$relative_path" == "$item" ]] || [[ "$relative_path" == "$item/"* ]]; then
                skip=true
                break
            fi
        done

        if [[ "$skip" == true ]]; then
            continue
        fi

        # OS-specific fragments: *.macos.conf only on macOS, *.linux.conf only
        # on Linux. Lets us scope hosts (e.g. home-network services) per OS.
        if [[ "$relative_path" == *.macos.conf && "$OS" != "macos" ]]; then
            continue
        fi
        if [[ "$relative_path" == *.linux.conf && "$OS" != "linux" ]]; then
            continue
        fi

        local target="$HOME/$relative_path"
        local target_dir="${target%/*}"

        # Create parent directory if needed
        if [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
        fi

        # Backup existing file if it's not a symlink
        if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
            warn "Backing up existing $target to ${target}.backup"
            mv "$target" "${target}.backup"
        fi

        info "Linking: $relative_path"
        ln -sf "$file" "$target"

    done < <(find "$dotfiles_source" -type f -not -path "*/.git/*")
}

# =============================================================================
# Main
# =============================================================================

main() {
    info "Starting dotfiles bootstrap..."
    
    detect_os
    detect_package_manager
    check_secrets

    # Install dependencies
    setup_zsh
    if [[ "$OS" == "macos" ]]; then
        # On macOS the Brewfile is the source of truth for brew-installable
        # tools (fnm, gh, neovim, ripgrep, finch, casks, fonts, ...).
        setup_brew_bundle
    else
        # Linux: install tools individually per package manager.
        setup_fnm
        setup_neovim
        setup_gh
        setup_container_runtime
    fi
    setup_opencode

    # Symlink dotfiles
    symlink_dotfiles

    # Setup secrets (run after symlinks so config files exist)
    setup_wakatime
    setup_opencode_secrets
    setup_claude_secrets

    # Setup commit signing (run after symlinks so .gitconfig is in place)
    setup_signing

    # Compose ~/.ssh/config from Include fragments (after symlinks so the
    # config.d/ fragments are in place)
    setup_ssh_include

    info "Bootstrap complete!"
    warn "Remember to:"
    echo "  1. Restart your shell or run: source ~/.zshrc"
    echo "  2. Run 'gh auth login' to authenticate GitHub CLI"
    echo "  3. Run 'fnm install --lts' to install Node.js"
    echo "  4. Open nvim and let lazy.nvim install plugins"
    
    if [[ "$OS" == "macos" ]]; then
        echo "  5. Start Finch VM: finch vm start"
    fi
    
    if [[ -z "${WAKATIME_API_KEY:-}" ]]; then
        echo "  6. Set up WakaTime: edit ~/.wakatime.cfg with your API key"
    fi
}

main "$@"
