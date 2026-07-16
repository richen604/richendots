{
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = "24";
    }
  ];
  environment.variables.XCURSOR_SIZE = "24";
}
