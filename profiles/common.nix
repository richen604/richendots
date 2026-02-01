{
  pkgs,
  hostvars,
  richenLib,
  ...
}:
{

  # USERS -------------------------------------------------------------
  users.users.richen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
      "networkmanager"
      # todo: should be in a dev module
      "docker"
    ];
    home = "/home/richen";
    initialPassword = "test";
    createHome = true;
    shell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";
  };
  users.defaultUserShell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";

  environment.systemPackages = [
    # yubikey tools
    pkgs.yubikey-manager
    pkgs.yubikey-personalization
    pkgs.yubikey-touch-detector

    # age encryption with yubikey support
    pkgs.age
    pkgs.age-plugin-yubikey
    pkgs.pam_u2f

    # wrappers
    richenLib.wrappers.zsh
    richenLib.wrappers.keepassxc
    richenLib.wrappers.git

    # other utils
    pkgs.tealdeer

    # nix tools
    pkgs.nixfmt
    pkgs.nil

    # cli utilities
    pkgs.bat
    pkgs.eza
    pkgs.tree
    pkgs.htop
    pkgs.fastfetch
    pkgs.neovim
    pkgs.tmux
    pkgs.less

    # system utilities
    pkgs.killall
    pkgs.gnumake
    pkgs.fzf
    pkgs.trash-cli
    pkgs.gawk
    pkgs.coreutils
    pkgs.bash-completion
    pkgs.unzip
    pkgs.cpufrequtils

    # network/hardware
    pkgs.networkmanager
    pkgs.lm_sensors
    pkgs.pciutils
    pkgs.wpa_supplicant

    # filesystem
    pkgs.ntfs3g
    pkgs.exfat

    # custom scripts
    (pkgs.callPackage ./scripts/reboot-to.nix { })
    (pkgs.callPackage ./scripts/git-commit-date.nix { })
  ];

  # required for zsh to catch all completions
  environment.pathsToLink = [ "/share/zsh" ];

  programs.nix-ld.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.openssh.enable = true;
  security.polkit.enable = true;

  boot = {
    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      extraEntries = ''
        menuentry "UEFI Firmware Settings" {
          fwsetup
        }
      '';
    };
  };

  # docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # networking
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # SSH
      22
    ];
    allowedUDPPorts = [
      # DHCP
      68
      546
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.settings.allow-import-from-derivation = false;
  nix.settings.trusted-users = [
    "root"
    "richen"
  ];

  # turn off bloat
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    dev.enable = false;
    nixos.enable = false;
  };

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";
  networking.hostName = hostvars.hostname;

  # fonts
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
      # fixes gohufont not having bold weights
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
  console = {
    # FIXME: good terminal font?
    # font = "Terminus32x16";
    keyMap = "us";
    packages = with pkgs; [
      terminus_font
    ];
  };
}
