{ pkgs, ... }: {

  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://nix-darwin.github.io/nix-darwin/manual/index.html
  #
  # TODO Feel free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # Packages here are reproducible, rollbackable, and available to all users.
  # For GUI apps, we use Homebrew casks which handle macOS app bundles better
  # and have a larger selection of macOS-specific applications.
  environment.systemPackages = with pkgs; [
    ack
    argocd
    ast-grep # Fast and polyglot tool for code searching, linting, rewriting
    atuin # Shell history sync with optional encryption
    bashInteractive
    bat # Clone of cat(1) with syntax highlighting and Git integration
    bats # Bash Automated Testing System
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
    fzf # Command-line fuzzy finder written in Go (includes built-in zsh integration)
    fzf-git-sh
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
    mise # Runtime version manager (formerly rtx)
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
    qemu # Machine emulator and virtualizer
    ripgrep
    screen
    sheldon # Fast, configurable, shell plugin manager
    shellcheck
    ssh-copy-id
    tmux
    tree # Display directories as trees (with optional color/HTML output)
    trivy
    wget
    woff2 # Webfont compression
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
    };

    taps = [
      "homebrew/services"
      "mediosz/tap"
      "nikitabobko/tap"
      "rcmdnk/file"
      "cj-systems/gitflow-cjs"
      "neurosnap/tap"
    ];

    # `brew install`
    # Packages here either aren't in nixpkgs, need better macOS integration,
    # or have specific reasons to use brew (noted in comments).
    brews = [
      "archey4"
      "coreutils" # GNU File, Shell, and Text utilities
      "curl" # Do not install curl via nixpkgs, it's not working well on macOS!
      "firebase-cli" # Firebase CLI - better Node.js compatibility via Homebrew
      "gnupg" # GNU Pretty Good Privacy (PGP) - better macOS keychain integration
      "qqqa"
      "rbenv"
      "rust" # Better toolchain management via rustup
      "sfnt2woff" # Font tools
      "sfnt2woff-zopfli"
      "tailscale" # Better macOS daemon integration via brew
      "yabai" # Needs brew for SIP-related features
      "zmx"
    ];

    # `brew install --cask`
    #
    casks = [
      "adobe-digital-editions"
      "aerospace"
      "anytype"
      "arc"
      "balenaetcher"
      "bartender"
      "beyond-compare"
      "calibre"
      "cardhop"
      "cheatsheet"
      "claude"
      "claude-code"
      "dash"
      "deepl"
      "devtoys"
      "finicky"
      "fman"
      "gcloud-cli"
      "ghostty"
      "git-credential-manager"
      "gitbutler"
      "glide-browser"
      "istat-menus"
      "istherenet"
      "jaikoz"
      "jetbrains-toolbox"
      "karabiner-elements"
      "lens"
      "logi-options+"
      "mouseless@preview"
      "ngrok"
      "ollama-app"
      "ollamac"
      "opencode-desktop"
      "raycast"
      "slack"
      "stats"
      "steam"
      "sublime-text"
      "swipeaerospace"
      "tabby"
      "the-unarchiver"
      "ticktick"
      "uhk-agent"
      "visualvm"
      "wezterm"
      "zen"
    ];
  };
}
