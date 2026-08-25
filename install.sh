#!/usr/bin/env bash
# install.sh — one-command setup for the Archlinux Omarchy theme + shell replica.
# Re-runnable: backs up on first run, then just refreshes everything.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$HOME/.config/omarchy/themes"
THEME_NAME="archlinux"
THEME_PATH="$THEMES_DIR/$THEME_NAME"
MARKER="$HOME/.config/omarchy/.archlinux-dotfiles-installed"
BLUR_MARKER='namespace = "omarchy-bar".*blur = true'

echo "==> Archlinux Omarchy setup"

# 1. Stage the theme files (dotfiles/ is the replica and stays out of the theme dir)
if [[ "$REPO_DIR" != "$THEME_PATH" ]]; then
  mkdir -p "$THEMES_DIR"
  rm -rf "$THEME_PATH"
  mkdir -p "$THEME_PATH"
  for f in colors.toml ghostty.conf icons.theme preview.png \
           shell.bar.toml shell.launcher.toml shell.menu.toml \
           shell.notifications.toml shell.popups.toml shell.tooltip.toml; do
    [[ -f "$REPO_DIR/$f" ]] && cp "$REPO_DIR/$f" "$THEME_PATH/$f"
  done
  [[ -d "$REPO_DIR/backgrounds" ]] && cp -r "$REPO_DIR/backgrounds" "$THEME_PATH/"
  echo "   + theme staged -> $THEME_PATH"
else
  echo "   = already running from the theme dir; skipping stage"
fi

# 2. Frosted glass: blur translucent surfaces + the bar layer
LOOKNFEEL="$HOME/.config/hypr/looknfeel.lua"
if ! grep -qE "$BLUR_MARKER" "$LOOKNFEEL" 2>/dev/null; then
  if [[ -f "$LOOKNFEEL" ]]; then
    cp "$LOOKNFEEL" "$LOOKNFEEL.bak.$(date +%s)"
    cat >> "$LOOKNFEEL" <<'EOF'

-- Archlinux theme - frosted glass
hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 3 } } })
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true })
EOF
  else
    mkdir -p "$HOME/.config/hypr"
    cat > "$LOOKNFEEL" <<'EOF'
-- Look'n'feel (created by omarchy-archlinux-setup)
-- Archlinux theme - frosted glass
hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 3 } } })
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true })
EOF
  fi
  echo "   + frosted blur added to looknfeel.lua (backup made)"
else
  echo "   = frosted blur already present"
fi

# 3. Replica: plugins, bar layout, fastfetch, update script
if [[ -d "$REPO_DIR/dotfiles" ]]; then
  if [[ ! -f "$MARKER" ]]; then
    TS="$(date +%s)"
    [[ -f "$HOME/.config/omarchy/shell.json" ]] && cp "$HOME/.config/omarchy/shell.json" "$HOME/.config/omarchy/shell.json.bak.$TS"
    [[ -d "$HOME/.config/omarchy/plugins" ]] && cp -r "$HOME/.config/omarchy/plugins" "$HOME/.config/omarchy/plugins.bak.$TS"
    [[ -f "$HOME/.config/fastfetch/config.jsonc" ]] && cp "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak.$TS"
    touch "$MARKER"
    echo "   + first-run backups saved (remove $MARKER to re-back-up)"
  else
    echo "   = backups already taken"
  fi

  mkdir -p "$HOME/.config/omarchy/plugins"
  cp -r "$REPO_DIR"/dotfiles/plugins/rob.* "$HOME/.config/omarchy/plugins/" 2>/dev/null || true
  cp "$REPO_DIR/dotfiles/shell.json" "$HOME/.config/omarchy/shell.json"
  mkdir -p "$HOME/.config/omarchy/bin"
  cp "$REPO_DIR/dotfiles/bin/system-update-count" "$HOME/.config/omarchy/bin/system-update-count"
  chmod +x "$HOME/.config/omarchy/bin/system-update-count"
  mkdir -p "$HOME/.config/fastfetch"
  cp "$REPO_DIR/dotfiles/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  echo "   + plugins, bar layout, fastfetch, and update script installed"
fi

# 4. Apply
echo "==> Applying theme (may pause briefly - this is normal)"
timeout 30 omarchy theme set "$THEME_NAME" >/dev/null 2>&1 || true
hyprctl reload >/dev/null 2>&1 || true

# 5. Verify
echo "==> Done. Verify with:"
echo "     omarchy theme current     # -> Archlinux"
echo "     hyprctl configerrors      # -> empty = no errors"