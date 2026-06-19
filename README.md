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
| `OPENCODE_BEDROCK_API_KEY` | AWS Bedrock API key (used by both OpenCode and Claude Code) |

If you skip secrets during bootstrap, you can configure them later:
- WakaTime: Edit `~/.wakatime.cfg`
- OpenCode: Edit `~/.config/opencode/opencode.json` (`provider.amazon-bedrock.options.apiKey`)
- Claude Code: Edit `~/.claude/settings.json` (`env.AWS_BEARER_TOKEN_BEDROCK`)

> The committed config files keep these fields empty; `bootstrap.sh` injects the
> Bedrock key from `OPENCODE_BEDROCK_API_KEY`. Runtime/session state
> (`~/.claude.json`, `~/.claude/sessions/`, caches, etc.) is git-ignored.

## Structure

```
.
├── .aws/
│   ├── config          # AWS CLI profiles
│   └── credentials     # Placeholder (prevents accidental long-lived keys)
├── .claude/
│   └── settings.json   # Claude Code settings (Bedrock token injected)
├── .config/
│   ├── herdr/          # herdr (agent multiplexer) config.toml
│   ├── nvim/           # Neovim + LazyVim config
│   └── opencode/       # OpenCode config + skills
├── .ssh/
│   ├── config.d/
│   │   ├── 00-dotfiles.conf  # Portable SSH hosts (github.com, etc.)
│   │   └── 10-home.macos.conf # macOS-only hosts (linked only on macOS)
│   └── allowed_signers       # Public keys trusted for SSH commit signing
├── .gitconfig          # Git config with aliases + SSH commit signing
├── .zshrc              # Zsh config
├── Brewfile            # macOS packages (brew bundle)
├── bootstrap.sh        # Setup script
└── secrets.template    # Template for secrets
```

## macOS packages

On macOS, brew-installable tools, casks, and fonts are declared in the
`Brewfile` and installed via `brew bundle`. `bootstrap.sh` runs this
automatically on macOS (replacing the per-tool installs used on Linux). To
install or update packages manually:

```sh
brew bundle --file=Brewfile
```

To capture newly installed packages back into the Brewfile:

```sh
brew bundle dump --file=Brewfile --force
```

On Linux, packages are installed individually via the detected package manager
(apt/dnf/yum/pacman).

## Rust

`bootstrap.sh` installs the stable Rust toolchain via `rustup` (`setup_rust`):
on macOS `rustup` comes from the Brewfile (keg-only) and its bin is added to
`PATH` in `.zshrc`; on Linux it's installed with the upstream `rustup` script
into `~/.cargo`. Manage toolchains with `rustup` and build with `cargo` as usual.

## SSH config

`~/.ssh/config` is composed via `Include`, so portable hosts coexist with
machine- or corporate-managed config (e.g. Amazon WSSH writes into
`~/.ssh/config` directly):

- **`.ssh/config.d/00-dotfiles.conf`** (tracked) — portable hosts shared across
  all machines, including the `github.com` signing/auth key. Symlinked into
  `~/.ssh/config.d/`.
- **`.ssh/config.d/10-home.macos.conf`** (tracked, macOS only) — hosts that
  should only exist on macOS machines (e.g. `rpi-pw.local`, a home-network
  service). `bootstrap.sh` only symlinks `*.macos.conf` fragments on macOS (and
  `*.linux.conf` fragments on Linux).
- **`~/.ssh/config.d/99-local.conf`** (NOT tracked) — put machine-specific or
  corporate hosts here, or leave them in `~/.ssh/config` below the `Include`.

`bootstrap.sh` injects `Include config.d/*.conf` at the top of `~/.ssh/config`
if it is missing (it never overwrites an existing `~/.ssh/config`). The
`Include` is placed first so dotfile hosts win SSH's first-match resolution.

## Supported Platforms

| OS | Package Manager |
|----|-----------------|
| macOS | Homebrew |
| Ubuntu/Debian | apt |
| Fedora | dnf |
| Amazon Linux | yum |
| Arch | pacman |
