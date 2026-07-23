{
  pkgs,
  richenLib,
  ...
}:
let
  swaylockTheme = import ./swaylock/_theme.nix {
    inherit (pkgs) lib;
    theme = richenLib.theme;
  };
  toSwaylockConf =
    attrs:
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.concatLists (
        pkgs.lib.mapAttrsToList (
          name: value:
          if pkgs.lib.isBool value then pkgs.lib.optional value name else [ "${name}=${toString value}" ]
        ) attrs
      )
    );
  config = pkgs.writeText "swaylock-config" (
    toSwaylockConf (
      {
        daemonize = true;
        clock = true;
        # this is a hack to ensure the wallpaper is in closure
        image = "${
          pkgs.runCommandLocal "swaylock-wallpaper" { } ''
            mkdir -p $out
            cp ${./swaybg/wall.png} $out/wall.png
          ''
        }/wall.png";
        scaling = "fill";
        effect-blur = "5x5";
        effect-vignette = "1:1";
        font = "GohuFont uni14 Nerd Font Propo";
        font-size = 120;
        indicator = true;
        indicator-radius = 220;
        indicator-thickness = 12;
        datestr = "%b-%d";
        timestr = "%H:%M";
        ignore-empty-password = true;
      }
      // swaylockTheme.colors
    )
  );
in
richenLib.lib.wrapPackage {
  package = pkgs.swaylock-effects;
  flags."--config" = config;
  passthru.config.path = config;
}
