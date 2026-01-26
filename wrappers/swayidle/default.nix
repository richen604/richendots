{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  swayidleWrapper = pkgs.callPackage ./module.nix { inherit inputs; };

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
in
(swayidleWrapper.apply {
  pkgs = pkgs;
  extraPackages = [ richenLib.wrappers.swaylock ];
  extraArgs = [ "-w" ];
  events = [
    # 10 minutes
    {
      type = "timeout";
      timeout = 10;
      command = "swaylock";
    }

    # 25 minutes - turn off all monitors
    {
      type = "timeout";
      timeout = 15;
      command = toString dpmsOff;
      resume = toString dpmsOn;
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
      command = toString dpmsOn;
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
  ];
}).wrapper
