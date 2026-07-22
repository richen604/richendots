{ pkgs, richenLib, ... }:
let
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
          ${richenLib.wrappers.mango-fern}/bin/mmsg dispatch create_virtual_output >/dev/null 2>&1 || true
        elif [ "$real_enabled" -gt 0 ] && [ "$headless_enabled" -gt 0 ]; then
          ${richenLib.wrappers.mango-fern}/bin/mmsg dispatch destroy_all_virtual_output >/dev/null 2>&1 || true
        fi
      fi

      sleep 1
    done
  '';
in
{
  systemd.user.services.mango-headless-output = {
    description = "Create a Mango virtual output when no real displays are enabled";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "mango-session.target" ];
    serviceConfig = {
      ExecStart = "${mangoHeadlessOutput}/bin/mango-headless-output";
      Restart = "always";
      RestartSec = 1;
    };
  };

  systemd.user.services.equibop.serviceConfig = {
    ExecStartPre = "${waitForEquibopOutput}/bin/wait-for-equibop-output";
    TimeoutStartSec = "infinity";
  };
}
