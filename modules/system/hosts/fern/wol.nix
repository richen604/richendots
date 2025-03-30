{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.fern.wol;
in
{
  options.modules.fern.wol = {
    enable = lib.mkEnableOption "Wake-on-LAN support";
    interface = lib.mkOption {
      type = lib.types.str;
      description = "Network interface to enable WoL on";
      example = "enp7s0";
    };
  };

  config = lib.mkIf cfg.enable {

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
