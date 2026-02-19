{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }:
  {
    _class = "wrapper";

    options = {
      "config.conf" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = "";
        description = ''
          content of the mango config file in multiline string format
        '';
      };
      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.path = config."config.conf".path;
        description = "path to the mango config file to be used instead of the default one.";
      };
      "autostart.sh" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = "";
        description = ''
          additional commands to run on mango start as a bash script. 
          omit shebang
          automatically appends exec-once=autostart.sh to mango config
        '';
        example = ''
          nm-applet &
          blueman-applet &
          keepassxc --minimize-to-tray &
        '';
      };
      autoStartFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.path = lib.mkIf (config."autostart.sh".content != "") (
          config.pkgs.writeScriptBin "mango-autostart" ''
            #!/usr/bin/env bash
            ${config."autostart.sh".path}
          ''
        );
        description = "path to the auto start script file.";
      };
    };

    config = {
      "config.conf".content = lib.mkMerge [
        ""
        (lib.mkIf (config."autostart.sh".content != "") ''
          exec-once=${config.autoStartFile.path}
        '')
      ];
      filesToPatch = [
        "share/wayland-sessions/mango.desktop"
      ];
      flags = {
        "-c" = toString config.configFile.path;
      };
      package = config.pkgs.mangowc;
      passthru.config.content = config."config.conf".content;
      passthru.autostart.content = config."autostart.sh".content;
      passthru.autostart.path = toString config.autoStartFile.path;
    };
  }
)
