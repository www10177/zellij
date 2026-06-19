#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/zellij"
LOCAL_BIN="${HOME}/.local/bin"
SERVICE_FILE="${HOME}/.config/systemd/user/zellij-web.service"
WEB_CONFIG="${CONFIG_DIR}/config-web.kdl"
WEB_SHELL="${LOCAL_BIN}/zellij-web-zsh"
WEB_ZSHRC="${CONFIG_DIR}/web-shell/.zshrc"
WEB_LAYOUT="${CONFIG_DIR}/layouts/codex-remote.kdl"

mkdir -p "${CONFIG_DIR}/web-shell" "${CONFIG_DIR}/layouts" "${LOCAL_BIN}"

cat > "${WEB_SHELL}" <<'EOF'
#!/usr/bin/env sh
set -eu

export ZDOTDIR="${ZELLIJ_WEB_ZDOTDIR:-$HOME/.config/zellij/web-shell}"
export ZELLIJ_WEB_SHELL=1

if [ "$#" -gt 0 ]; then
  exec /usr/bin/zsh "$@"
fi

exec /usr/bin/zsh -i
EOF

cat > "${WEB_LAYOUT}" <<'EOF'
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }

        children

        pane size=1 borderless=true {
            plugin location="file:/home/www10177/5.MISC/utilities/codex-quota-zellij/target/wasm32-wasip1/release/codex_quota_zellij.wasm"
        }

        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }

    tab name="remote" {
        pane command="/home/www10177/.local/bin/zellij-web-zsh"
    }
}
EOF

cat > "${WEB_ZSHRC}" <<'EOF'
# Zellij Web/remote shell profile.
# Keep this prompt intentionally simple: no p10k, no instant prompt, no right prompt.

export LANG=en_US.UTF-8

export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH:/opt/nvim-linux-x86_64/bin/"
export PATH="/home/www10177/.local/share/solana/install/active_release/bin:$PATH"
export PATH="/home/www10177/.cargo/bin:$PATH"
export PATH="/home/www10177/go/bin:$PATH"
export PATH="/home/www10177/.local/bin:$PATH"
export PATH="${PATH}:/usr/local/cuda-13.3/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/cuda-13.3/lib64"
export PATH="${PATH}:/home/www10177/5.MISC/utilities/bins"

PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '
RPROMPT=''

bindkey "\033[1~" beginning-of-line
bindkey "\033[4~" end-of-line

alias lf='lf -single'
alias zellija='zellij attach'
alias now='date +%Y-%m-%d-%H.%M.%S'
alias lg='lazygit'
alias wol='wakeonlan 2C:F0:5D:2E:69:FE'
alias xclip='xclip -selection clipboard'
alias xc='xclip'
alias rclone-gui='rclone rcd --rc-web-gui --rc-addr 192.168.88.187:8080 --rc-web-gui-no-open-browser --rc-user www10177 --rc-pass rclone'
alias rsync='rsync -avzrP'
alias Gemini='gemini --yolo'
alias vim='nvim'
alias kbase='cd /home/www10177/.local/share/knowledges && gemini'
alias pwx="pwd | tr -d '\n' | xclip"
alias Codex='codex --danger-full-access'
alias Agy='agy --dangerously-skip-permissions'

export NVM_DIR="/home/www10177/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
export AIRFLOW_HOME=/home/airflow
export EDITOR=nvim

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

if [[ -f "/home/www10177/.config/cf/completions/_cf.zsh" ]]; then
  source "/home/www10177/.config/cf/completions/_cf.zsh"
fi

if [[ -s "/home/www10177/.oh-my-zsh/completions/_bun" ]]; then
  source "/home/www10177/.oh-my-zsh/completions/_bun"
fi

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
EOF

if [[ ! -f "${WEB_CONFIG}" ]]; then
  cp "${CONFIG_DIR}/config.kdl" "${WEB_CONFIG}"
fi

perl -0pi -e 's{// default_shell "fish"}{default_shell "/home/www10177/.local/bin/zellij-web-zsh"}; s{default_layout "codex"}{default_layout "codex-remote"}' "${WEB_CONFIG}"

chmod +x "${WEB_SHELL}"

if [[ -f "${SERVICE_FILE}" ]]; then
  perl -0pi -e 's{/home/www10177/\.local/bin/zellij web }{/home/www10177/.local/bin/zellij --config /home/www10177/.config/zellij/config-web.kdl web }' "${SERVICE_FILE}"
  systemctl --user daemon-reload
  systemctl --user restart zellij-web.service
fi
