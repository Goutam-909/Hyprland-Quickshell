

# ── Aliases (eza) ─────────────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -lah --icons'
alias la='eza -a --icons'
alias lt='eza --tree --icons'
alias l='eza -lh --icons'

# ── Starship prompt ───────────────────────────────────────────────────────────
starship init fish | source
source /usr/share/cachyos-fish-config/cachyos-config.fish
# ── Suppress greeting ─────────────────────────────────────────────────────────
set -g fish_greeting ""
set -x LANG en_US.utf8
set -x LC_ALL en_US.utf8
fish_add_path ~/.local/bin
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
