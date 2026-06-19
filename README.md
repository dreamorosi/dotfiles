# Dotfiles

Personal dotfiles for macOS and Linux (Ubuntu, Fedora, Amazon Linux, Arch).

## What's Included

- **Shell**: zsh with oh-my-zsh and [pure](https://github.com/sindresorhus/pure) prompt
- **Editor**: Neovim with LazyVim
- **Tools**: fnm (Node.js), GitHub CLI
- **Configs**: git, ssh, AWS, OpenCode

## Quick Start

```sh
git clone https://github.com/dreamorosi/dotfiles.git ~/Codes/dotfiles
cd ~/Codes/dotfiles

# Set up secrets (optional but recommended)
cp secrets.template secrets.env
# Edit secrets.env with your API keys
source secrets.env

# Run bootstrap
./bootstrap.sh
```

## Post-Install

After bootstrap completes:

1. Restart your shell: `source ~/.zshrc`
2. Authenticate GitHub CLI: `gh auth login`
3. Install Node.js: `fnm install --lts`
4. Open `nvim` to let lazy.nvim install plugins
5. Add your SSH key to GitHub as a **Signing Key** (for the "Verified" badge on
   commits): <https://github.com/settings/ssh/new> (Key type: *Signing Key*).
   Commits are signed with `~/.ssh/github` via SSH signing.

## Secrets

The following secrets can be configured in `secrets.env`:

| Variable | Description |
|----------|-------------|
| `WAKATIME_API_KEY` | [WakaTime](https://wakatime.com/settings/api-key) API key |
| `OPENCODE_BEDROCK_API_KEY` | AWS Bedrock API key for OpenCode |

If you skip secrets during bootstrap, you can configure them later:
- WakaTime: Edit `~/.wakatime.cfg`
- OpenCode: Edit `~/.config/opencode/opencode.json`

## Structure

```
.
├── .aws/
│   ├── config          # AWS CLI profiles
│   └── credentials     # Placeholder (prevents accidental long-lived keys)
├── .config/
│   ├── nvim/           # Neovim + LazyVim config
│   └── opencode/       # OpenCode config + skills
├── .ssh/
│   ├── config          # SSH host aliases
│   └── allowed_signers # Public keys trusted for SSH commit signing
├── .gitconfig          # Git config with aliases + SSH commit signing
├── .zshrc              # Zsh config
├── bootstrap.sh        # Setup script
└── secrets.template    # Template for secrets
```

## Supported Platforms

| OS | Package Manager |
|----|-----------------|
| macOS | Homebrew |
| Ubuntu/Debian | apt |
| Fedora | dnf |
| Amazon Linux | yum |
| Arch | pacman |
