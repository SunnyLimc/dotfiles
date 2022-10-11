# os specific
case "$(uname -s)" in
Linux*) OST=linux ;;
CYGWIN* | MINGW* | MSYS*) OST=win ;;
*) OST=other ;;
esac
islinux() {
  [[ $OST = "linux" ]]
}
iswin() {
  [[ $OST = "win" ]]
}

# env
export EDITOR=nvim
export VISUAL=nvim
# export PAGER="nvim +Man!"
# export MANPAGER="nvim +Man!"
if islinux; then
  PATH=$HOME/winhome/.wsl:$HOME/.local/bin:$PATH
  alias ssha="start-stop-daemon --start --oknodo --pidfile "$HOME/.ssh/wsl-ssh-agent-relay.pid" --name wsl-ssh-agent-r --make-pidfile --background --startas "$HOME/dotfile/bin/wsl-ssh-agent-relay" foreground"
  export SSH_AUTH_SOCK=${HOME}/.ssh/wsl-ssh-agent.sock
fi

# alias
# useful for WSL
alias vimdiff="nvim -d"
alias vim=nvim
islinux && alias wt="wt.exe -p 'Ubuntu Here'"
alias exp="explorer.exe ."
islinux && alias cdi="cd $HOME/winhome"
islinux && alias win="pwsh.exe"
# phrase
alias ll="ls -alh"
alias gs="git status"
alias mv="mv -i"
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
islinux && alias resd="$HOME/.sync-dotfile.sh"

# proxy
# MUST BE at the top of anything executable
source $HOME/.proxy.sh set

# install it with $(brew --prefix)/opt/fzf/install
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# shortcuts
# bind ctrl-backspace to delete-word
bindkey '^H' backward-kill-word

# antigen
source $HOME/.scripts/libs/antigen.zsh
antigen use oh-my-zsh
antigen bundle git
antigen bundle pip
antigen bundle command-not-found
antigen bundle z
# antigen bundle vi-mode
antigen bundle colored-man-pages
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zimfw/completion
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle agkozak/zsh-z
# antigen bundle zsh-users/zsh-history-substring-search
# antigen bundle jeffreytse/zsh-vi-mode
iswin && antigen theme zimfw/asciiship
# antigen theme robbyrussell
# apply
antigen apply

# zsh-vi-mode compatibility
# zvm_bindkey viins '^[[A' history-beginning-search-backward
# zvm_bindkey viins '^[[B' history-beginning-search-forward
# zvm_bindkey vicmd '^[[A' history-beginning-search-backward
# zvm_bindkey vicmd '^[[B' history-beginning-search-forward

# less
export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
export LESS=' -R '

# brew
if islinux; then
  export HOMEBREW_NO_ENV_HINTS=1
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# git
if islinux; then
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0=http.proxy
  export GIT_CONFIG_VALUE_0=$HTTP_PROXY
fi

# gpg
# issue: https://github.com/microsoft/WSL/issues/4029
islinux && export GPG_TTY=$(tty)

# poetry
export PATH="$HOME/.poetry/bin:$PATH"

# nvm
# node-version-manager: https://github.com/nvm-sh/nvm
# PATH="$HOME/.local/bin:$PATH"
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# broot
islinux && source /home/limc/.config/broot/launcher/bash/br

# linux conda
# >>> conda initialize >>>
if islinux; then
  __conda_setup="$('/home/limc/.anaconda3/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "/home/limc/.anaconda3/etc/profile.d/conda.sh" ]; then
      . "/home/limc/.anaconda3/etc/profile.d/conda.sh"
    else
      export PATH="/home/limc/.anaconda3/bin:$PATH"
    fi
  fi
  unset __conda_setup
fi
# <<< conda initialize <<<

# starship
islinux && eval "$(starship init zsh)"

