{
  ...
}:
{
  imports = [
    ./git.nix
    ./obs.nix
    ./games.nix
    ./zsh.nix
    ./dev.nix
    ./kde-connect.nix
  ];

  manual.manpages.enable = false;
  programs.home-manager.enable = true;
}
