{
  pkgs,
  richenLib,
  dpmsTimeout ? 1500,
  suspendTimeout ? 3600,
  ...
}:
let
  dpmsOff = pkgs.writeShellScript "dpms-off" ''
    wlr-randr | grep -E '^[^ ]' | awk '{print $1}' | while read -r output; do
      wlr-randr --output "$output" --off
    done
  '';
  dpmsOn = pkgs.writeShellScript "dpms-on" ''
    wlr-randr | grep -E '^[^ ]' | awk '{print $1}' | while read -r output; do
      wlr-randr --output "$output" --on
    done
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
      command = "swaylock";
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
      command = "systemctl suspend";
    }
    {
      type = "before-sleep";
      command = "swaylock";
    }
    {
      type = "lock";
      command = "swaylock";
    }
    {
      type = "after-resume";
      command = toString dpmsOn;
    }
    {
      type = "unlock";
      command = "pkill -USR1 swaylock";
    }
  ]
  ++ [ "$@" ];
}
