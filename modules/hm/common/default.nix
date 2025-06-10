{
  pkgs,
  ...
}:
{
  imports = [
    ./git.nix
    ./expo-dev.nix
    ./obs.nix
    ./games.nix
    ./easyeffects.nix
    ./zsh.nix
    ./dev.nix
    ./kde-connect.nix
  ];
}
