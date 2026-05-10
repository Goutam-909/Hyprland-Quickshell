#!/usr/bin/env fish
# Apply Fish terminal colors
# Pure Fish script - no bash needed!

set content (cat ~/.config/uchiha/colors/fish-sequences.txt)
for part in (string split ']' $content)
    if test -n "$part"
        printf '\033]%s\033\\' "$part"
    end
end
