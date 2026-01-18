{
  config,
  inputs,
  pkgs,
  richenLib,
  ...
}:
{
  imports = [
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    inputs.hydenix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/system/hosts/fern
    ../common/private.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      osConfig = config;
    };
    users."richen" =
      { config, ... }:
      {
        imports = [
          inputs.hydenix.homeModules.default
          ../../modules/hm/users/richen
        ];

        desktops.hydenix = {
          enable = true;
          hostname = "fern";
        };

        home.stateVersion = "25.05";
        modules = {
          common = {
            git.enable = true;
            dev.enable = true;
            obs.enable = true;
            games.enable = true;
            zsh.enable = true;
          };
          # TODO: make obsidian.nix work on any host
          obsidian.enable = true;
        };
      };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/newdev/richendots";
  };
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;
  # for spotify
  services.flatpak.enable = true;
  environment.systemPackages = [
    pkgs.spicetify-cli
    richenLib.wrappers.firefox
    richenLib.wrappers.keepassxc
  ];

  hydenix = {
    enable = true;
    hostname = "fern";
    timezone = "America/Vancouver";
    locale = "en_CA.UTF-8";
  };

  users.users.richen = {
    isNormalUser = true;
    initialPassword = "hydenix";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    shell = pkgs.zsh;
  };

  # FONTS --------------------------------------------------------------

  environment.etc."gtk-3.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';

  environment.etc."gtk-4.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.gohufont
      terminus_font
    ];
    fontconfig = {
      enable = true;
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test name="family" compare="contains">
              <string>Gohu</string>
            </test>
            <edit name="embolden" mode="assign">
              <bool>true</bool>
            </edit>
          </match>
        </fontconfig>
      '';
      defaultFonts = {
        monospace = [ "GohuFont uni14 Nerd Font Propo" ];
        sansSerif = [ "GohuFont uni14 Nerd Font Propo" ];
        serif = [ "GohuFont uni14 Nerd Font Propo" ];
      };
    };
  };

  system.stateVersion = "25.05";
}
