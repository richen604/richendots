{
  services.nixpull = {
    enable = true;
    role = "client";
    server.user = "richen";
    notify = {
      enable = true;
      users = [ "richen" ];
    };
  };
}
