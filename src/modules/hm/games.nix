{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    prismlauncher
    # Common Java packages used by Minecraft
    jdk17
    # Performance mods often need these
    gcc
    glibc
  ];

}
