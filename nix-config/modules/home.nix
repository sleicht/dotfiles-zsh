{ username, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.11";
  };

  # import sub modules
  imports = [
  ];

# Makes sense for user specific applications that shouldn't be available system-wide
  home.packages = [
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
  };

  home.sessionVariables = {
  };

  home.sessionPath = [
    "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    profileExtra = ''
      if [ -f "$HOME/.dotfiles/.config/zprofile" ]; then
          . "$HOME/.dotfiles/.config/zprofile"
      fi
    '';
    envExtra = ''
      if [ -f "$HOME/.dotfiles/.config/zshenv" ]; then
          . "$HOME/.dotfiles/.config/zshenv"
      fi
    '';
    initContent = ''
      if [ -f "$HOME/.dotfiles/.config/zshrc" ]; then
          . "$HOME/.dotfiles/.config/zshrc"
      fi

      # Add any additional configurations here
      export PATH=$HOME/.nix-profile/bin:$HOME/bin:$PATH
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';
  };
}
