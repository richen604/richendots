{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  let
    # convert events to command-line arguments
    eventsToArgs =
      events:
      let
        # generate arguments for a single event
        eventToArgs =
          event:
          if event.type == "timeout" then
            [
              "timeout"
              (toString event.timeout)
              event.command
            ]
            ++ lib.optionals (event ? resume && event.resume != null && event.resume != "") [
              "resume"
              event.resume
            ]
          else if event.type == "before-sleep" then
            [
              "before-sleep"
              event.command
            ]
          else if event.type == "after-resume" then
            [
              "after-resume"
              event.command
            ]
          else if event.type == "lock" then
            [
              "lock"
              event.command
            ]
          else if event.type == "unlock" then
            [
              "unlock"
              event.command
            ]
          else if event.type == "idlehint" then
            [
              "idlehint"
              (toString event.timeout)
            ]
          else
            throw "Unknown swayidle event type: ${event.type}";
      in
      lib.concatMap eventToArgs events;
  in
  {
    _class = "wrapper";
    options = {
      events = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = ''
          List of swayidle events.
          See {manpage}`swayidle(1)` for available event types.
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments to pass to swayidle.";
      };
    };

    config = {
      args = config.extraArgs ++ eventsToArgs config.events;
      package = config.pkgs.swayidle;
    };
  }
)
