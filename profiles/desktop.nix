{
  lib,
  richenLib,
  pkgs,
  ...
}:
let
  waitForRealOutput = pkgs.writeShellScriptBin "wait-for-real-output" ''
    set -eu

    while true; do
      outputs="$(${pkgs.wlr-randr}/bin/wlr-randr --json 2>/dev/null || true)"
      if [ -n "$outputs" ] && printf '%s' "$outputs" | ${pkgs.jq}/bin/jq -e 'any(.[]; (.enabled != false) and ((.name | test("^HEADLESS-[0-9]+$")) | not))' >/dev/null; then
        break
      fi
      sleep 1
    done
  '';

  waitForEquibopOutput = pkgs.writeShellScriptBin "wait-for-equibop-output" ''
    set -eu

    while true; do
      outputs="$(${pkgs.wlr-randr}/bin/wlr-randr --json 2>/dev/null || true)"
      if [ -n "$outputs" ] && printf '%s' "$outputs" | ${pkgs.jq}/bin/jq -e 'any(.[]; (.enabled != false) and (.model == "DELL E2020H"))' >/dev/null; then
        break
      fi
      sleep 1
    done
  '';

  mangoHeadlessOutput = pkgs.writeShellScriptBin "mango-headless-output" ''
    set -eu

    while true; do
      outputs="$(${pkgs.wlr-randr}/bin/wlr-randr --json 2>/dev/null || true)"
      if [ -n "$outputs" ]; then
        real_enabled="$(printf '%s' "$outputs" | ${pkgs.jq}/bin/jq '[.[] | select((.enabled != false) and ((.name | test("^HEADLESS-[0-9]+$")) | not))] | length')"
        headless_enabled="$(printf '%s' "$outputs" | ${pkgs.jq}/bin/jq '[.[] | select((.enabled != false) and (.name | test("^HEADLESS-[0-9]+$")))] | length')"

        if [ "$real_enabled" -eq 0 ] && [ "$headless_enabled" -eq 0 ]; then
          ${richenLib.wrappers.mango}/bin/mmsg dispatch create_virtual_output >/dev/null 2>&1 || true
        elif [ "$real_enabled" -gt 0 ] && [ "$headless_enabled" -gt 0 ]; then
          ${richenLib.wrappers.mango}/bin/mmsg dispatch destroy_all_virtual_output >/dev/null 2>&1 || true
          ${pkgs.systemd}/bin/systemctl --user try-restart waybar.service >/dev/null 2>&1 || true
        fi
      fi

      sleep 1
    done
  '';
in
{
  imports = [
    (import ../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      waybarPackage = richenLib.wrappers.waybar;
      swayidlePackage = richenLib.wrappers.swayidle;
      extraWantedServices = [ "sunshine.service" ];
    })
  ];

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
    richenLib.wrappers.waybar
  ];

  # greetd configuration
  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango}/bin/mango";
      user = "richen";
    };
    default_session = initial_session;
  };

  systemd.user.services.sunshine = {
    wantedBy = lib.mkForce [ "mango-session.target" ];
    partOf = lib.mkForce [ "mango-session.target" ];
    after = lib.mkForce [ "mango-session.target" ];
    wants = lib.mkForce [ ];
  };

  systemd.user.services.mango-headless-output = {
    description = "Create a Mango virtual output when no real displays are enabled";
    partOf = [ "mango-session.target" ];
    after = [ "mango-session.target" ];
    wantedBy = [ "mango-session.target" ];
    serviceConfig = {
      ExecStart = "${mangoHeadlessOutput}/bin/mango-headless-output";
      Restart = "always";
      RestartSec = 1;
    };
  };

  systemd.user.services.waybar.serviceConfig.ExecStartPre =
    "${waitForRealOutput}/bin/wait-for-real-output";

  systemd.user.services.equibop.serviceConfig.ExecStartPre =
    "${waitForEquibopOutput}/bin/wait-for-equibop-output";

  # theme settings
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = "24";
    }
  ];
  environment.variables.XCURSOR_SIZE = "24";

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango.config.content;

  xdg.portal.configPackages = [
    richenLib.wrappers.mango
  ];

}
