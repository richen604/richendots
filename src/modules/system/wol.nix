{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.wol;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options.modules.wol = {
    enable = mkEnableOption "Wake-on-LAN support";
    interface = mkOption {
      type = types.str;
      description = "Network interface to enable WoL on";
      example = "enp7s0";
    };
  };

  config = mkIf cfg.enable {

    # Network settings for WoL
    networking = {
      interfaces.${cfg.interface} = {
        wakeOnLan.enable = true;
      };
    };

    # Systemd service to enable WoL
    systemd.services.enable-wol = {
      description = "Enable Wake-on-LAN";
      after = [
        "network.target"
        "NetworkManager.service"
      ];
      wantedBy = [
        "multi-user.target"
        "sleep.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.ethtool}/bin/ethtool -s ${cfg.interface} wol g
        '';
        ExecStop = ''
          ${pkgs.ethtool}/bin/ethtool -s ${cfg.interface} wol g
        '';
      };
    };
  };
}
