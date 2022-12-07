#!/bin/bash
# .bashrc

parse_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Uncomment the following line if you don't like systemctl's auto-paging feature:
WHITE_BK="\[\e[47m\]"
CYAN="\[\e[1;36m\]"
BLK="\[\e[0;37m\]"
GREEN="\[\e[1;32m\]"
GREEN_BK="\[\e[0;42m\]"
PS1="${BLK}[${CYAN}uraniborg${BLK}:${GREEN}\W${GREEN_BK}\$(parse_git_branch)${BLK}]$\[\e[0m\] "

# User specific aliases and functions
alias pyhttp="python -m SimpleHTTPServer"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

if [[ ! $TERM =~ screen ]]; then
	    exec tmux
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
