{ pkgs, richenLib, ... }:
{
  environment.systemPackages = [
    richenLib.wrappers.opencode

    # dev tools
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
