{
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = "48";
    }
  ];
  environment.variables.XCURSOR_SIZE = 48;
}
