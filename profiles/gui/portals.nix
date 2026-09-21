{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    config = {
      mango = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "luminous" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "luminous" ];
        "org.freedesktop.impl.portal.Inhibit" = [ ];
      };
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-luminous
      xdg-desktop-portal-gtk
    ];
  };
}
