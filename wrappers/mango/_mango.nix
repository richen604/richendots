{
  inputs,
  pkgs,
  richenLib,
  cursorSize,
  tagLayouts,
  config,
  env ? { },
  ...
}:
let
  mangoPackage = pkgs.callPackage ./_package.nix { src = inputs.mango; };
  mangoBase = pkgs.callPackage ./_base-config.nix { inherit cursorSize richenLib; };
  tagRules = pkgs.lib.concatMapStringsSep "\n" (
    tag:
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (
        monitor: layout: "tagrule=id:${toString tag},monitor_model:${monitor},layout_name:${layout}"
      ) tagLayouts
    )
  ) (pkgs.lib.range 1 9);
  fullConfig = mangoBase + "\n" + tagRules + "\n" + config;
in
richenLib.lib.wrapPackage {
  package = mangoPackage;
  inherit env;
  wrapper =
    {
      envString,
      exePath,
      ...
    }:
    ''
      ${envString}
      exec ${pkgs.lib.escapeShellArg (toString exePath)} -c "$HOME/.config/mango/config.conf" "$@"
    '';
  passthru.config.content = fullConfig;
}
