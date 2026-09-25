{ lib, richenLib, ... }:
{
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size =
        lib.gvariant.mkInt32 richenLib.hostVars.cursorSize;
    }
  ];

  environment.variables.XCURSOR_SIZE = toString richenLib.hostVars.cursorSize;
}
