{
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
      interval = "Mon *-*-* 03:00:00";
    };
  };
}
