

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
# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end

    # Colors
    if test -f ~/.config/uchiha/colors/terminal/sequences.txt
        cat ~/.config/uchiha/colors/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
