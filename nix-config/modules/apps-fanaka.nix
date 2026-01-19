{ ... }: {

  ##########################################################################
  #
  #  Fanaka-specific applications
  #
  #  These are personal apps that are only installed on Fanaka machines.
  #  Separated from apps.nix for cleaner organisation.
  #
  ##########################################################################

  homebrew = {
    # Mac App Store apps (Fanaka-specific)
    masApps = {
      "iFinance 5" = 1500241909;
      "kChat" = 6443845553;
      "LilyView" = 529490330;
      "MacFamilyTree 10" = 1567970985;
      "Tailscale" = 1475387142;
      "WhatsApp" = 310633997;
    };

    # Homebrew casks (Fanaka-specific)
    casks = [
      "affinity-designer"
      "affinity-photo"
      "affinity-publisher"
      "cleanmymac"
      "daisydisk"
      "dropbox"
      "fantastical"
      "google-chrome"
      "google-drive"
      "google-earth-pro"
      "kdrive"
      "kobo"
      "logseq"
      "nvidia-geforce-now"
      "onlyoffice"
      "orbstack"
      "path-finder"
      "raindropio"
      "readdle-spark"
      "roon"
      "tidal"
      "ubersicht"
      "virtualbox"
      "vivaldi"
      "vlc"
      "xld"
    ];
  };
}
