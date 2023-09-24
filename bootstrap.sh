#!/usr/bin/env bash

set -e

# Create Wakatime config
printf "\n[settings]\napi_key = $WAKATIME_API_KEY\n" > ~/.wakatime.cfg

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install fnm
curl -fsSL https://fnm.vercel.app/install | zsh

# Install pure prompt
mkdir -p "$HOME/.zsh"
git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"