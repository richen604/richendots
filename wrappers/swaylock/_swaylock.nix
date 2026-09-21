{
  pkgs,
  richenLib,
  fontSize ? 52,
  indicatorRadius ? 180,
  ...
}:
let
  swaylockTheme = import ./_theme.nix {
    inherit (pkgs) lib;
    inherit (richenLib) theme;
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
        image = ./../swaybg/wall.png;
        scaling = "fill";
        effect-blur = "5x5";
        effect-vignette = "1:1";
        font = "GohuFont uni14 Nerd Font Propo";
        font-size = fontSize;
        indicator = true;
        indicator-radius = indicatorRadius;
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
