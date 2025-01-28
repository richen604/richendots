{ userConfig, pkgs, ... }:

{
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
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=plex"
      "gid=plex"
      "permissions"
      "acl"
    ];
  };

  users.groups.plex = {
    name = "plex";
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
    "d /data/plex 0775 ${userConfig.username} ${userConfig.username}"
  ];

  environment.systemPackages = with pkgs; [
    plex-desktop
  ];
}
