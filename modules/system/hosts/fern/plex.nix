{
  pkgs,
  config,
  lib,
  ...
}:

# TODO: proxy, requires passwords
# TODO: sonarr search, requires passwords
# TODO: qbitorrent web instance, requires passwords

let
  cfg = config.modules.fern.plex;
in
{
  options.modules.fern.plex = {
    enable = lib.mkEnableOption "plex";
  };

  config = lib.mkIf cfg.enable {
    services.plex = {
      enable = true;
      openFirewall = true;
      user = "plex";
      group = "plex";
      dataDir = "/var/lib/plex";
      accelerationDevices = [
        "*"
      ];
    };

    fileSystems."/data/plex" = {
      device = "/dev/sda1";
      fsType = "ntfs";
      options = [
        "rw"
        "uid=plex"
        "gid=plex"
        "permissions"
        "acl"
        "dmask=0002"
        "fmask=0002"
        "nofail"
      ];
    };

    users.groups.plex = {
      name = "plex";
      members = [ "richen" ];
    };
    users.users.plex = {
      group = "plex";
      home = "/var/lib/plex";
      createHome = true;
      isSystemUser = true;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/plex 0775 plex plex"
      "Z /var/lib/plex - plex plex"
      "d /data/plex 0775 plex plex"
      "Z /data/plex - plex plex"
    ];

    # Add qBittorrent service configuration
    systemd.services.qbittorrent = {
      description = "qBittorrent";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "richen";
        Group = "plex";
        ExecStart = "${pkgs.qbittorrent-enhanced-nox}/bin/qbittorrent-nox";
        Restart = "on-failure";
      };
    };

    environment.systemPackages = with pkgs; [
      plex-desktop
    ];
  };
}
