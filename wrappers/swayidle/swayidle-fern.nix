{
  pkgs,
  richenLib,
  ...
}:
let
  recoverDisplay = pkgs.writeShellScript "recover-odyssey-after-resume" ''
    ${pkgs.coreutils}/bin/sleep 5

    display_is_healthy() {
      outputs="$(${pkgs.wlr-randr}/bin/wlr-randr --json 2>/dev/null)" || return 1
      printf '%s\n' "$outputs" | ${pkgs.jq}/bin/jq -e '
        any(.[];
          .name == "DP-2"
          and .model == "Odyssey G70D"
          and any(.modes[]; .width == 3840 and .height == 2160 and .refresh >= 143)
        )
      ' >/dev/null
    }

    if display_is_healthy; then
      exit 0
    fi

    ${pkgs.util-linux}/bin/logger -t swayidle "DP-2 resumed with bad identity or modes; retraining DisplayPort"

    for attempt in 1 2; do
      ${pkgs.wlr-randr}/bin/wlr-randr --output DP-2 --off || true
      ${pkgs.coreutils}/bin/sleep 3
      ${pkgs.wlr-randr}/bin/wlr-randr --output DP-2 --on || true
      ${pkgs.coreutils}/bin/sleep 5

      if display_is_healthy; then
        ${pkgs.util-linux}/bin/logger -t swayidle "DP-2 recovered after attempt $attempt"
        exit 0
      fi
    done

    ${pkgs.util-linux}/bin/logger -p user.warning -t swayidle "DP-2 recovery failed after two attempts"
  '';
in
pkgs.callPackage ./_swayidle.nix {
  inherit richenLib;
  afterResumeExtraCommand = recoverDisplay;
}
