{ ... }:
{

  imports = [
    ./hardware-configuration.nix
    ../../profiles/common.nix
  ];

  networking.networkmanager.enable = true;
  networking.interfaces.wlp3s0.wakeOnLan.enable = true;
  users.users.richen.extraGroups = [ "docker" ];

  virtualisation.docker.enable = true;

  programs.nh = {
    enable = true;
    flake = "/mnt/dev/richendots";
  };

  # nixpull server configuration
  services.nixpull = {
    enable = true;
    role = "builder";
    flake = "/mnt/dev/richendots";
    server.user = "richen";
    build = {
      hosts = [
        "cedar"
        "fern"
        "oak"
      ];
      maxJobs = 1;
      interval = "Mon *-*-* 03:00:00"; # weekly at 3am on mondays
    };
  };

  system.stateVersion = "25.05";
}
