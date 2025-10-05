{ pkgs, ... }: {

  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    ack
    argocd
    atuin
    bashInteractive
    bat # Clone of cat(1) with syntax highlighting and Git integration
    bat-extras.prettybat
    bat-extras.batdiff
    bat-extras.batpipe
    broot
    bottom
    carapace
    docker
    duf
    dust
    emojify
    eza
    fd
    findutils # Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
    firebase-tools
    fzf # Command-line fuzzy finder written in Go
    fzf-git-sh
    fzf-zsh
    zsh-fzf-tab
    zsh-forgit
    zsh-fzf-history-search
    gh # GitHub command-line tool
    git
    git-lfs
    gitflow
    git-town
    glab
    gnused # Install GNU `sed`, overwriting the built-in `sed`.
    gnugrep
    kubernetes-helm
    htop
    httpie # http client
    jq # Lightweight and flexible command-line JSON processor
    just # use Justfile to simplify nix-darwin's commands
    lazydocker
    lazygit
    lsd # Clone of ls with colorful output, file type icons, and more
    mas # Mac App Store command-line interface
    mackup
    moreutils # Install some other useful utilities like `sponge`.
    nano
    nanorc
    nodejs_22
    ncdu
    neovim
    nushell
    oh-my-posh
    openssh
    openssl
    opentofu
    p7zip
    peco
    pinentry_mac
    podman
    ripgrep
    screen
    sheldon # Fast, configurable, shell plugin manager
    shellcheck
    ssh-copy-id
    tmux
    tree # Display directories as trees (with optional color/HTML output)
    trivy
    wget
    zoxide
    zsh # UNIX shell (command interpreter)
    zsh-abbr # Auto-expanding abbreviations manager for zsh, inspired by fish
    zsh-completions
    zulu
  ];
  environment.variables.EDITOR = "nvim";

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";
  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      "Bitwarden" = 1352778147;
      "Microsoft Remote Desktop" = 1295203466;
      "Racompass" = 1538380685;
      "Xcode" = 497799835;

      # Fanaka
      "iFinance 5" = 1500241909;
      "kChat" = 6443845553;
      "LilyView" = 529490330;
      "MacFamilyTree 10" = 1567970985;
      "Tailscale" = 1475387142;
      "WhatsApp" = 310633997;
    };

    taps = [
      "homebrew/services"
      "nikitabobko/tap"
      "rcmdnk/file"
      "cj-systems/gitflow-cjs"
    ];

    # `brew install`
    brews = [
      "archey4"
      "curl" # no not install curl via nixpkgs, it's not working well on macOS!
      "coreutils" # GNU File, Shell, and Text utilities
      "gnupg" # GNU Pretty Good Privacy (PGP) package
      "libyaml"
      "gmp"
      "mise"
      "rust"
      "rbenv"
      "yabai"
      ### Install font tools.
      "sfnt2woff"
      "sfnt2woff-zopfli"
      "woff2"
    ];

    # `brew install --cask`
    #
    casks = [
      "aerospace"
      "adobe-digital-editions"
      "anytype"
      "arc"
      "balenaetcher"
      "bartender"
      "beyond-compare"
      "calibre"
      "cardhop"
      "cheatsheet"
      "dash"
      "deepl"
      "devtoys"
      "finicky"
      "fman"
      "ghostty"
      "git-credential-manager"
      "gitbutler"
      "google-chrome"
      "gcloud-cli"
      "google-drive"
      "google-earth-pro"
      "istat-menus"
      "iterm2"
      "istherenet"
      "jaikoz"
      "jetbrains-toolbox"
      "karabiner-elements"
      "kdrive"
      "kobo"
      "lens"
      "logi-options+"
      "logitech-options"
      "logseq"
      "mouseless@preview"
      "ngrok"
      "nvidia-geforce-now"
      "ollama-app"
      "ollamac"
      "onlyoffice"
      "orbstack"
      "path-finder"
      "protonvpn"
      "raindropio"
      "raycast"
      "readdle-spark"
      "roon"
      "slack"
      "stats"
      "steam"
      "sublime-text"
      "tabby"
      "the-unarchiver"
      "ticktick"
      "tidal"
      "ubersicht"
      "uhk-agent"
      "visualvm"
      "vivaldi"
      "vlc"
      "wezterm"
      "xld"
      "zen"

      # Fanaka
      "affinity-designer"
      "affinity-photo"
      "affinity-publisher"
      "cleanmymac"
      "daisydisk"
      "dropbox"
      "fantastical"
      "google-chrome"
      "google-drive"
      "kdrive"
      "logseq"
      "roon"
      "readdle-spark"
      "tidal"
      "xld"
    ];
  };
}
