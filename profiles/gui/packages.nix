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
    richenLib.wrappers.udiskie
    pkgs.yubikey-manager
    pkgs.equibop
    pkgs.wlr-randr
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.cliphist
    pkgs.polkit_gnome
    pkgs.xdg-utils
    pkgs.libnotify
    pkgs.wlsunset
    pkgs.grim
    pkgs.slurp
    pkgs.brightnessctl
    pkgs.libinput-gestures
    pkgs.libinput
    pkgs.dpms-off
    pkgs.obsidian
    pkgs.zed-editor
    pkgs.wayland-pipewire-idle-inhibit
    (pkgs.prismlauncher.override {
      jdks = [ pkgs.jdk21 ];
    })
  ];

  programs.gpu-screen-recorder.enable = true;
  programs.steam.enable = true;
}
