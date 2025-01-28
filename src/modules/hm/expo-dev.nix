{ pkgs, ... }:

{
  home.packages = with pkgs; [

    android-studio
    android-tools
    sdkmanager
    nodePackages.pnpm
    nodePackages.expo-cli
    nodejs_20
  ];
}
