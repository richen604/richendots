{
  hostvars,
  pkgs,
  richenLib,
  ...
}:
let
  vicinaePackage =
    if hostvars.profile == "laptop" then
      richenLib.wrappers.vicinae-laptop
    else
      richenLib.wrappers.vicinae;
in
{
  environment.systemPackages = [
    richenLib.wrappers.kitty
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    richenLib.wrappers.swaync
    vicinaePackage
    richenLib.wrappers.satty
    richenLib.wrappers.glide
    richenLib.wrappers.keepassxc
    pkgs.yubikey-manager
    pkgs.equibop
    pkgs.wlr-randr
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.cliphist
    pkgs.polkit_gnome
    pkgs.xdg-utils
    pkgs.libnotify
    richenLib.wrappers.wlsunset
    pkgs.grim
    pkgs.slurp
    pkgs.brightnessctl
    pkgs.libinput-gestures
    pkgs.libinput
    pkgs.dpms-off
    (pkgs.writeShellScriptBin "steam-game-run" ''
      mkdir -p "$HOME/.cache/dxvk" "$HOME/.cache/nvidia"

      export PROTON_ENABLE_WAYLAND=1
      export PROTON_DXVK_LOWLATENCY=1
      export DXVK_STATE_CACHE=1
      export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk"
      export __GL_SHADER_DISK_CACHE=1
      export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia"
      export __GL_SHADER_DISK_CACHE_SIZE=10737418240

      exec "$@"
    '')
  ];

  programs.gpu-screen-recorder.enable = true;
  programs.steam.enable = true;
}
