
# Key bindings

# Home / End
bindkey "^[[H"    beginning-of-line
bindkey "^[[F"    end-of-line
bindkey "^[[1~"   beginning-of-line
bindkey "^[[4~"   end-of-line

# Ctrl+Left/Right — skip words
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Alt+Left/Right — skip words (alternate)
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# Treat / as a word boundary for word-motion
WORDCHARS=${WORDCHARS//\//}

# Shift+Left/Right
bindkey "^[[1;2C" forward-char
bindkey "^[[1;2D" backward-char


parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

bp () {
  git push -u origin HEAD:ghmeier/$(parse_git_branch)
}

fbp () {
  git push --force-with-lease origin HEAD:ghmeier/$(parse_git_branch)
}


gwt() {
  local branch="${1:-$(git branch --show-current)}"
  local folder="./worktrees/${branch}"
  git worktree add "${folder}" "${branch}"
  cd "${folder}"
}

# Create worktree with new branch
gwtn() {
  local branch="$1"
  local folder="./worktrees/${branch}"
  git worktree add -b "${branch}" "${folder}"
  echo 'Initializing environment'
  cp ./.env "${folder}/.env"
  cd "${folder}"
  npm ci --prefer-offline
  uv venv
}

# Prune local branches that have been merged or deleted on remote
git-prune() {
  local main_branch="${1:-main}"

  # Fetch and prune remote tracking branches
  git fetch --prune

  # Get list of branches to delete (merged into main, excluding main and current branch)
  local branches=$(git branch --merged "$main_branch" | grep -v "^\*" | grep -v "$main_branch")

  if [ -z "$branches" ]; then
    echo "No merged branches to prune."
  else
    echo "Deleting merged branches:"
    echo "$branches"
    echo "$branches" | xargs git branch -d
  fi

  # Show branches with deleted remote tracking branch (gone)
  local gone_branches=$(git branch -vv | grep ': gone]' | awk '{print $1}')

  if [ -n "$gone_branches" ]; then
    echo ""
    echo "Branches with deleted remote (use -D to force delete):"
    echo "$gone_branches"
    read "confirm?Delete these branches? [y/N] "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "$gone_branches" | xargs git branch -D
    fi
  fi
}

# Dry run version - just shows what would be deleted
git-prune-dry() {
  local main_branch="${1:-main}"

  echo "=== Merged branches (safe to delete) ==="
  git branch --merged "$main_branch" | grep -v "^\*" | grep -v "$main_branch"

  echo ""
  echo "=== Branches with deleted remote ==="
  git fetch --prune
  git branch -vv | grep ': gone]' | awk '{print $1}'
}


function set_terminal_title() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    print -Pn "\e]2;${branch}\a"
  else
    print -Pn "\e]2;%1~\a"
  fi
}
precmd_functions+=(set_terminal_title)

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%F{green}(%b)%f'

# Set up the prompt (with git branch name)
setopt PROMPT_SUBST

PROMPT='[%F{cyan}uraniborg%f${vcs_info_msg_0_}:%1~]$ '


# User specific aliases and functions
alias pyhttp="python -m SimpleHTTPServer"
alias pyvirtualenv="source .env/bin/activate"
alias gmaster='git checkout master && git pull origin master'
alias gmain='git checkout main && git pull origin main'
alias gitcleanup="git branch --merged | perl -ne 'print if not /\\* master/' | xargs git branch -d"
alias gittrash="find . -name \"*.orig\" -o -name \"*BACKUP*\" -o -name \"*LOCAL*\" -o -name \"*REMOTE*\" -o -name \"*BASE*\" | xargs rm"
alias gitclean="gittrash && git gc && git remote prune origin && git branch --merged | grep -v \* | xargs git branch -D"
alias gu='git pull && git submodule update --init --recursive && npm ci'
alias gri='git rebase -i origin/main'

export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="/opt/homebrew/bin:$PATH"

export LDFLAGS="-L/usr/local/opt/openblas/lib"
export CPPFLAGS="-I/usr/local/opt/openblas/include"

export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
fpath[1,0]="/opt/homebrew/share/zsh/site-functions";
eval "$(/usr/bin/env PATH_HELPER_ROOT="/opt/homebrew" /usr/libexec/path_helper -s)"
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";


# Stop verbose npm console output.
export DISABLE_OPENCOLLECTIVE=true

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

# bun completions
[ -s "/Users/ghmeier/.bun/_bun" ] && source "/Users/ghmeier/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# uv
eval "$(uv generate-shell-completion zsh)"
export UV_ENV_FILE=.env
