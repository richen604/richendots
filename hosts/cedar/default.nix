{
  pkgs,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ../../profiles/common.nix
  ];

  networking.networkmanager.enable = true;
  networking.interfaces.wlp3s0.wakeOnLan.enable = true;

  # todo: unsure if im keeping this
  # services.code-server = {
  #   enable = true;
  #   user = "richen";
  #   group = "users";
  #   host = "127.0.0.1";
  #   port = 8080;
  #   auth = "none";
  #   package = pkgs.vscode-with-extensions.override {
  #     vscode = pkgs.code-server;
  #     vscodeExtensions = [ ];
  #   };
  # };

  environment.systemPackages = [
    pkgs.kitty
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/mnt/dev/richendots";
  };
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;

  system.stateVersion = "25.05";
}
