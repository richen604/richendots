{ pkgs, ... }:
{
  imports = [
    ../../common/nix.nix
  ];

  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    wpa_supplicant
    kitty
  ];
}
