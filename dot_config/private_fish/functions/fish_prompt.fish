function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Tokyo Night colors
    set -l cyan 7dcfff
    set -l magenta bb9af7
    set -l blue 7aa2f7

    set -l suffix '❯'
    if functions -q fish_is_root_user; and fish_is_root_user
        set suffix '#'
    end

    # Write pipestatus
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    # Git branch with icon (using powerline branch symbol)
    set -l git_info ''
    if command -sq git
        set -l branch (git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set git_info (set_color $magenta)" "(printf '\ue0a0')" $branch"$normal
        end
    end

    # First line: cat emoji, hostname, path, and git info
    echo -s '🐈 '(set_color $blue)$hostname(set_color normal)' '(set_color $cyan)(prompt_pwd)$git_info$normal

    # Second line: status and prompt character
    echo -n -s $prompt_status (set_color $magenta)"$suffix "$normal
end
