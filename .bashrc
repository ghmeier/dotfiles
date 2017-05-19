# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

parse_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
WHITE_BK="\[\e[47m\]"
CYAN="\[\e[1;36m\]"
BLK="\[\e[0;37m\]"
GREEN="\[\e[1;32m\]"
GREEN_BK="\[\e[0;42m\]"
PS1="${BLK}[${CYAN}uraniborg${BLK}:${GREEN}\W${GREEN_BK}\$(parse_git_branch)${BLK}]$\[\e[0m\] "

# User specific aliases and functions
alias pyhttp="python -m SimpleHTTPServer"

dmenv () {
	eval "$(docker-machine env $1)"
}

togopath () {
	cd $HOME/git/go/src/github.com/ghmeier/$1
}

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export JAVA_HOME=/usr/java/latest
export GOPATH=$HOME/git/go
export PATH=$PATH:$GOPATH/bin

if [[ ! $TERM =~ screen ]]; then
	    exec tmux
fi
