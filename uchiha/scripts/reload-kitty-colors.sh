#!/usr/bin/env bash
# Reload Kitty terminal colors after matugen updates

# Check if colors-kitty.conf was updated
KITTY_COLORS="$HOME/.config/uchiha/colors/colors-kitty.conf"

if [[ ! -f "$KITTY_COLORS" ]]; then
    exit 0
fi

# Reload all Kitty instances
if command -v kitty &>/dev/null; then
    # Send reload signal to all kitty instances
    killall -SIGUSR1 kitty 2>/dev/null
    
    # Alternative: Use kitty remote control (if enabled)
    # kitty @ set-colors --all --configured "$KITTY_COLORS" 2>/dev/null
fi

# Apply Fish colors to all terminals (including Kitty)
FISH_SEQUENCES="$HOME/.config/uchiha/colors/fish-sequences.txt"
if [[ -f "$FISH_SEQUENCES" ]]; then
    for pty in /dev/pts/*; do
        if [[ $pty =~ ^/dev/pts/[0-9]+$ ]]; then
            {
                while IFS=']' read -r part; do
                    if [[ -n "$part" ]]; then
                        printf '\033]%s\033\\' "$part" > "$pty" 2>/dev/null
                    fi
                done < "$FISH_SEQUENCES"
            } & disown
        fi
    done
fi
