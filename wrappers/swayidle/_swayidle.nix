{
  pkgs,
  richenLib,
  dpmsTimeout ? 1500,
  suspendTimeout ? 3600,
  afterResumeExtraCommand ? null,
  ...
}:
let
  dpmsOff = pkgs.writeShellScript "dpms-off" ''
    ${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep -E '^[^ ]' | ${pkgs.gawk}/bin/awk '{print $1}' | while read -r output; do
      ${pkgs.wlr-randr}/bin/wlr-randr --output "$output" --off
    done
  '';
  dpmsOn = pkgs.writeShellScript "dpms-on" ''
    ${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep -E '^[^ ]' | ${pkgs.gawk}/bin/awk '{print $1}' | while read -r output; do
      ${pkgs.wlr-randr}/bin/wlr-randr --output "$output" --on
    done
  '';
  afterResume = pkgs.writeShellScript "after-resume" ''
    ${dpmsOn}
    ${pkgs.lib.optionalString (afterResumeExtraCommand != null) (toString afterResumeExtraCommand)}
  '';
  eventsToArgs =
    events:
    pkgs.lib.concatMap (
      event:
      if event.type == "timeout" then
        [
          "timeout"
          (toString event.timeout)
          event.command
        ]
        ++ pkgs.lib.optionals (event ? resume && event.resume != null && event.resume != "") [
          "resume"
          event.resume
        ]
      else
        [
          event.type
          event.command
        ]
    ) events;
in
richenLib.lib.wrapPackage {
  package = pkgs.swayidle;
  args = [
    "-w"
  ]
  ++ eventsToArgs [
    {
      type = "timeout";
      timeout = 300;
      command = "${richenLib.wrappers.swaylock}/bin/swaylock";
    }
    {
      type = "timeout";
      timeout = dpmsTimeout;
      command = toString dpmsOff;
      resume = toString dpmsOn;
    }
    {
      type = "timeout";
      timeout = suspendTimeout;
      command = "${pkgs.systemd}/bin/systemctl suspend";
    }
    {
      type = "before-sleep";
      command = "${richenLib.wrappers.swaylock}/bin/swaylock";
    }
    {
      type = "lock";
      command = "${richenLib.wrappers.swaylock}/bin/swaylock";
    }
    {
      type = "after-resume";
      command = toString afterResume;
    }
    {
      type = "unlock";
      command = "${pkgs.procps}/bin/pkill -USR1 swaylock";
    }
  ]
  ++ [ "$@" ];
}
