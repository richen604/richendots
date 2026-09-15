{ pkgs, richenLib, ... }:
{
  environment.systemPackages = [
    richenLib.wrappers.opencode
    pkgs.rtk
    pkgs.nixfmt
    pkgs.nil
    pkgs.nixd
    pkgs.nodejs
    pkgs.bun
    pkgs.gh
    pkgs.gnumake
    pkgs.direnv
  ];
}
