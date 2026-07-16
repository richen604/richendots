{ pkgs, ... }:
let
  catppuccinGtkPython = pkgs.python313.override {
    packageOverrides = _pyFinal: pyPrev: {
      catppuccin = pyPrev.catppuccin.overridePythonAttrs (_old: {
        doCheck = false;
        pythonImportsCheck = [ ];
      });
    };
  };
in
{
  environment.systemPackages = [
    pkgs.bibata-cursors
    (pkgs.catppuccin-papirus-folders.override {
      accent = "green";
      flavor = "mocha";
    })
    (pkgs.catppuccin-gtk.override {
      accents = [ "green" ];
      python3 = catppuccinGtkPython;
      size = "compact";
      variant = "mocha";
    })
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "catppuccin-mocha-green-compact";
          color-scheme = "prefer-dark";
          font-name = "GohuFont uni14 Nerd Font Propo";
          cursor-theme = "Bibata-Modern-Ice";
          icon-theme = "Papirus-Dark";
          font-antialiasing = "rgba";
          font-hinting = "full";
        };
      };
    }
  ];
  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Ice" ];
  environment.etc."gtk-3.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';
  environment.etc."gtk-4.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';
}
