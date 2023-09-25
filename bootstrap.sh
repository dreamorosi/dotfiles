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

# Symlink files
current_dir="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
dotfiles_source="${current_dir}"
deny_list=("debug.sh" "bootstrap.sh" ".git/")

while read -r file; do
    # Check if the file is in the deny list
    skip_file=false
    for item in "${deny_list[@]}"; do
        if [[ -d "${item}" && "${file}" == "${dotfiles_source}/${item}/"* ]] || [[ "${file}" == "${dotfiles_source}/${item}"* ]]; then
            printf 'Skipping file %s\n' "${file}"
            skip_file=true
            break
        fi
    done

    if [ "${skip_file}" = true ]; then
        continue
    fi

    # If not, we symlink it
    relative_file_path="${file#"${dotfiles_source}"/}"
    target_file="${HOME}/${relative_file_path}"
    target_dir="${target_file%/*}"

    if test ! -d "${target_dir}"; then
        mkdir -p "${target_dir}"
    fi

    printf 'Installing dotfiles symlink %s\n' "${target_file}"
    ln -sf "${file}" "${target_file}"

done < <(find "${dotfiles_source}" -type f)