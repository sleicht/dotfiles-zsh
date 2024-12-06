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
    neovim
    git
    just # use Justfile to simplify nix-darwin's commands
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
      "Ampado PRO" = 1423295407;
      "iFinance 5" = 1500241909;
      "kChat" = 6443845553;
      "LilyView" = 529490330;
      "MacFamilyTree 10" = 1567970985;
      "Numbers" = 409203825;
      "Phiewer PRO" = 1270923434;
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
      # "aria2"  # download tool
      "asdf"
      "ack"
      "archey4"
      "argocd"
      "bash" # Latest Bash version
      "bat" # Clone of cat(1) with syntax highlighting and Git integration
      "bat-extras" # Bash scripts that integrate bat with various command-line tools
      "broot"
      "bottom"
      "curl" # no not install curl via nixpkgs, it's not working well on macOS!
      "coreutils" # GNU File, Shell, and Text utilities
      "docker"
      "docker-completion"
      "docker-compose"
      "duf"
      "dust"
      "emojify"
      "eza"
      "findutils" # Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
      "fzf" # Command-line fuzzy finder written in Go
      "gh" # GitHub command-line tool
      "git" # Distributed revision control system
      "gnu-getopt" # dependency of git-flow-cjs
      "git-flow-cjs"
      "git-lfs"
      "glab"
      "gnu-sed" # Install GNU `sed`, overwriting the built-in `sed`.
      "gnupg" # GNU Pretty Good Privacy (PGP) package
      "grep"
      "gs"
      "helm"
      "htop"
      "httpie" # http client
      "imagemagick"
      "jfrog-cli"
      "jq" # Lightweight and flexible command-line JSON processor
      "lazydocker"
      "lazygit"
      "lsd" # Clone of ls with colorful output, file type icons, and more
      "mas" # if OS.mac? # Mac App Store command-line interface
      "mackup" # if OS.mac?
      "moreutils" # Install some other useful utilities like `sponge`.
      "ncdu"
      "neovim"
      "oh-my-posh"
      "openssh"
      "opentofu"
      "p7zip"
      "peco"
      "pkg-config"
      "pigz"
      "podman"
      "pv"
      "rename"
      "ripgrep"
      "rlwrap"
      "screen"
      "ssh-copy-id"
      "tmux"
      "tree" # Display directories as trees (with optional color/HTML output)
      "trivy"
      "uv"
      "vale"
      "vbindiff"
      "wget" # Install `wget` with IRI support.
      "yabai"
      "zopfli"
      "zoxide" # Shell extension to navigate your filesystem faster
      "sheldon" # Fast, configurable, shell plugin manager
      "zsh" # UNIX shell (command interpreter)
      "zsh-abbr" # Auto-expanding abbreviations manager for zsh, inspired by fish
      ### Install font tools.
      "sfnt2woff"
      "sfnt2woff-zopfli"
      "woff2"
#      "zsh-fast-syntax-highlighting"
    ];

    # `brew install --cask`
    #
    casks = [
      "stats" # beautiful system monitor

      "google-chrome"
      "google-drive"
      "google-earth-pro"
      "aerospace"
      "adobe-digital-editions"
      "arc"
      "balenaetcher"
      "bartender"
      "beyond-compare"
      "calibre"
      "cardhop"
      "cheatsheet"
      "claude"
      "dash"
      "deepl"
      "devtoys"
      "finicky"
      "fman"
      "git-credential-manager"
      "google-cloud-sdk"
      "istat-menus"
      "iterm2"
      "jaikoz"
      "jetbrains-toolbox"
      "jprofiler"
      "karabiner-elements"
      "kdrive"
      "kitty"
      "kobo"
      "lens"
      "logi-options+"
      "logitech-options"
      "logseq"
      "ngrok"
      "nvidia-geforce-now"
      "ollama"
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
      "vlc"
      "wezterm"
      "xld"

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
