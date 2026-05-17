#!/usr/bin/env bash
# Idempotent mise install. Runs once on container create.
#
# - mise binary goes to /usr/local/bin so it doesn't depend on ~/.local/bin
#   (which is root-owned when the named volume parents auto-create it).
# - The volume mount points under $HOME are chown'd to vscode so mise can
#   write its data and cache there.
set -euo pipefail

# Tilt's helm_resource extension is a python3 script; the base image doesn't
# ship it. Tiny dep, install via apt.
if ! command -v python3 >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends python3
  sudo rm -rf /var/lib/apt/lists/*
fi

# Fix ownership on volume-mounted dirs. Named volumes attach as root-owned
# by default; the user needs to write to them.
sudo install -d -o "$(id -u)" -g "$(id -g)" \
    "$HOME/.local" \
    "$HOME/.local/share" \
    "$HOME/.local/share/mise" \
    "$HOME/.cache" \
    "$HOME/.cache/mise" \
    "$HOME/.kube" \
    /commandhistory
sudo chown -R "$(id -u):$(id -g)" \
    "$HOME/.local" \
    "$HOME/.cache" \
    "$HOME/.kube" \
    /commandhistory 2>/dev/null || true

# Install mise globally if missing.
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run -o /tmp/mise-install.sh
  sudo env MISE_INSTALL_PATH=/usr/local/bin/mise bash /tmp/mise-install.sh
  rm -f /tmp/mise-install.sh
fi

# Activate mise in interactive bash and zsh, and add shims for non-interactive
# shells (the one VS Code uses to run postCreateCommand).
add_line() {
  local file=$1 line=$2
  grep -qF -- "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}
touch "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"
add_line "$HOME/.bashrc" 'eval "$(mise activate bash)"'
add_line "$HOME/.zshrc"  'eval "$(mise activate zsh)"'
add_line "$HOME/.profile" 'eval "$(mise activate bash --shims)"'
