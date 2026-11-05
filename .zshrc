# Lines configured by zsh-newuser-install
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt autocd
setopt correct
setopt notify
setopt numericglobsort
setopt promptsubst
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
unsetopt beep
# End of lines configured by zsh-newuser-install

# autocompletions import
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit
_zcd="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
if [[ -n ${_zcd}(#qN.mh+24) ]]; then
  compinit -d "$_zcd"          # full security check, once a day
else
  compinit -C -d "$_zcd"       # otherwise trust the cached dump
fi
unset _zcd



### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
# Use Turbo mode to defer plugin loading
zinit wait lucid for \
    zsh-users/zsh-syntax-highlighting \
    zsh-users/zsh-completions \
    zsh-users/zsh-autosuggestions \
    Aloxaf/fzf-tab \
    jeffreytse/zsh-vi-mode



### End of Zinit's installer chunk


# custom prompt
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/style.json)"

# aliases
alias clear="clear && fastfetch && echo '\n\n'"
alias ls="ls --color"
alias hypr="nvim ~/.config/hypr/hyprland.lua"
alias watchlist="nvim ~/Desktop/anime_watchlist.txt"
alias fix_hd2="nvim ~/Games/Steam/steamapps/compatdata/553850/pfx/drive_c/users/steamuser/AppData/Roaming/Arrowhead/Helldivers2/user_settings.config"
alias fix_nfs="sudo sysctl kernel.split_lock_mitigate=0"
alias activate_via="sudo chmod a+rw /dev/hidraw1"
alias deactivate_via="sudo chmod a-rw /dev/hidraw1"
alias fabric="source ~/.config/fabric/.venv/bin/activate && python ~/.config/fabric/main.py"
alias fabric_dev="source ~/.config/fabric_v2/.venv/bin/activate && python ~/.config/fabric_v2/main.py"
alias ..="cd .."
alias paint="kolourpaint"
# alias lsblk="lsblk -o label,name,size,type,mountpoint"
alias clc="qalc"
alias pypi_update="python -m build && python -m twine upload dist/*"
alias spatial="spatial-toggle"
alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings'
alias wlc=wl-copy
alias wlp=wl-paste
alias man="man -L en"

alias pyrefly="~/.local/share/nvim/mason/bin/pyrefly"


zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
source <(fzf --zsh)



node_init () {
    source /usr/share/nvm/init-nvm.sh
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

### yazi auto cd on quit ###
yz() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}


# bluetooth connect via fzf
btc() {
  local mac=$(bluetoothctl devices | fzf | awk '{print $2}')
  [ -n "$mac" ] && bluetoothctl connect "$mac"
}

ts() {
  local parser_dir=~/.local/share/nvim/site/parser

  if [[ $# -eq 0 ]]; then
    echo "Usage: ts <lang> <file> [tree-sitter parse options...]"
    echo "       ts -l | --list      list installed parsers"
    return 1
  fi

  if [[ $1 == "-l" || $1 == "--list" ]]; then
    ls "$parser_dir" | sed 's/\.so$//'
    return 0
  fi

  local lang=$1
  shift

  local parser="$parser_dir/${lang}.so"
  if [[ ! -f $parser ]]; then
    echo "No parser found for '$lang' (looked in $parser_dir)" >&2
    echo "Run 'ts -l' to see installed parsers." >&2
    return 1
  fi

  tree-sitter parse -l "$parser" --lang-name "$lang" "$@"
}


bindkey '^K' up-line-or-history
bindkey '^J' down-line-or-history
eval "$(zoxide init --cmd cd zsh)"
