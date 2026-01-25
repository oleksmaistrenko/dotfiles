if status is-interactive
    # Commands to run in interactive sessions can go here
    atuin init fish 2>&1 | grep -v "bind.*-k" | source
    bind down '_atuin_search'

    # Erase all up arrow bindings
    bind -e up
    bind -e \eOA
    bind -e \e\[A
    bind -M insert -e \eOA
    bind -M insert -e \e\[A
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
abbr -a -- gco 'git checkout'
abbr -a -- gpl 'git pull'
abbr -a -- gsw 'git switch'
# abbr -a -- tfp 'terraform plan'
# azure dev servers
abbr -a -- devb2c 'azsh dev b2c'
abbr -a -- devodesa 'azsh dev odesa'
abbr -a -- gprl 'gh pr list'

# Auto-update Homebrew every 24 hours
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400

function brewup --description "Update and upgrade Homebrew packages"
    brew update
    set outdated (brew outdated)
    if test -n "$outdated"
        echo "Upgrading outdated packages..."
        brew upgrade
        brew cleanup
    else
        echo "All packages are up to date!"
    end
end

function fish_greeting
    echo -e "let's do some nice stuff 💫\n"
end

function bind_bang
    switch (commandline -t)[-1]
        case "!"
            commandline -t -- $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function bind_dollar
    switch (commandline -t)[-1]
        case "!"
            commandline -f backward-delete-char history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

function fish_user_key_bindings
    bind ! bind_bang
    bind '$' bind_dollar
end

zoxide init fish 2>&1 | grep -v "bind.*-k" | source
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
