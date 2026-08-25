{
  pkgs,
  richenLib,
  ...
}:
let
  appId = "md.obsidian.Obsidian";
  obsidianTheme = import ./_theme.nix { inherit (richenLib) theme; };
  themeCss = pkgs.replaceVars ./theme.css obsidianTheme.replacements;
  ensureObsidian = pkgs.writeShellScript "ensure-obsidian-flatpak" ''
    set -eu

    if ${pkgs.flatpak}/bin/flatpak info ${appId} >/dev/null 2>&1; then
      exit 0
    fi

    ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo
    ${pkgs.flatpak}/bin/flatpak install --user --noninteractive flathub ${appId}
  '';
in
{
  services.flatpak.enable = true;

  systemd.user.services.obsidian-flatpak-install = {
    description = "Install the Obsidian Flatpak if missing";
    wantedBy = [ "mango-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ensureObsidian;
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 30;
    };
  };

  hjem.users.${richenLib.vars.username}.files = {
    "syncthing/obsidian/home/.obsidian/themes/richendots/manifest.json" = {
      type = "copy";
      permissions = "0644";
      source = ./manifest.json;
    };
    "syncthing/obsidian/home/.obsidian/themes/richendots/theme.css" = {
      type = "copy";
      permissions = "0644";
      source = themeCss;
    };
  };
}
