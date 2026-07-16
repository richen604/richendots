{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.gohufont
      terminus_font
    ];
    fontconfig = {
      enable = true;
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test name="family" compare="contains">
              <string>Gohu</string>
            </test>
            <edit name="embolden" mode="assign">
              <bool>true</bool>
            </edit>
          </match>
        </fontconfig>
      '';
      defaultFonts = {
        monospace = [ "GohuFont uni14 Nerd Font" ];
        sansSerif = [ "GohuFont uni14 Nerd Font Propo" ];
        serif = [ "GohuFont uni14 Nerd Font Propo" ];
      };
    };
  };
  console = {
    keyMap = "us";
    packages = with pkgs; [
      terminus_font
    ];
  };
}
