{ lib, ... }:
{
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = lib.gvariant.mkInt32 24;
    }
  ];
  environment.variables.XCURSOR_SIZE = "24";
}
