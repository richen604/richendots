{ pkgs, ... }:

{
  home.packages = with pkgs; [

    android-studio
    android-tools
    sdkmanager
    nodePackages.pnpm
    nodejs_20
  ];
}
