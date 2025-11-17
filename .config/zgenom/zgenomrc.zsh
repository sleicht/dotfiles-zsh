#!/usr/bin/env zsh

# Check for plugin and zgenom updates every 7 days
# This does not increase the startup time.
zgenom autoupdate

# if the init script doesn't exist
if ! zgenom saved; then
    echo "Creating a zgenom save"

    # Add this if you experience issues with missing completions or errors mentioning compdef.
    zgenom compdef

    # Ohmyzsh base library
    zgenom ohmyzsh
    # ohmzsh plugins
    zgenom ohmyzsh plugins/gitfast
    zgenom ohmyzsh plugins/zoxide
    zgenom ohmyzsh plugins/asdf
    zgenom ohmyzsh plugins/kubectl
    zgenom ohmyzsh plugins/gcloud
    zgenom ohmyzsh plugins/mvn

    # Install ohmyzsh osx plugin if on macOS
    [[ "$(uname -s)" = Darwin ]] && zgenom ohmyzsh plugins/macos

    # plugins
    zgenom loadall <<EOPLUGINS
        zsh-users/zsh-syntax-highlighting
        Aloxaf/fzf-tab
        junegunn/fzf-git.sh
        zsh-users/zsh-autosuggestions
        ptavares/zsh-sdkman
        matthieusb/zsh-sdkman
        /opt/homebrew/share/zsh-abbr
EOPLUGINS

    for script in ~/.zsh.d/*.zsh; do
      if [[ -r "$script" ]]; then
        zgenom load "$script"
      fi
    done

    for script in ~/.zsh.d.private/*.zsh; do
      if [[ -r "$script" ]]; then
        zgenom load "$script"
      fi
    done

    # completions
    zgenom load zsh-users/zsh-completions

    # theme
    zgenom ohmyzsh themes/arrow

    # save all to init script
    zgenom save

    # Compile your zsh files
    zgenom compile "$HOME/.zshrc"
    # Uncomment if you set ZDOTDIR manually
    # zgenom compile $ZDOTDIR

    # You can perform other "time consuming" maintenance tasks here as well.
    # If you use `zgenom autoupdate` you're making sure it gets
    # executed every 7 days.
    rbenv rehash
fi
