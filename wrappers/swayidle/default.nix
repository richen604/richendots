{
  pkgs,
  richenLib,
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
      else if event.type == "idlehint" then
        [
          "idlehint"
          (toString event.timeout)
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
    # 10 minutes
    {
      type = "timeout";
      timeout = 300;
      command = "swaylock";
    }

    # 25 minutes - turn off all monitors
    {
      type = "timeout";
      timeout = 1500;
      command = "${dpmsOff}/bin/dpms-off";
      resume = "${dpmsOn}/bin/dpms-on";
    }

    # 1 hour
    {
      type = "timeout";
      timeout = 3600;
      command = "systemctl hibernate";
    }

    # lock screen before system goes to sleep
    {
      type = "before-sleep";
      command = "swaylock";
    }

    # lock when systemd signals session should be locked
    {
      type = "lock";
      command = "swaylock";
    }

    # after resume, turn monitors back on
    {
      type = "after-resume";
      command = "${dpmsOn}/bin/dpms-on";
    }

    # unlock command
    {
      type = "unlock";
      command = "pkill -USR1 swaylock";
    }

    # set idle hint
    # {
    #   type = "idlehint";
    #   timeout = 300;
    # }
  ]
  ++ [ "$@" ];
}
