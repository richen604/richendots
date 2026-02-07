{
  inputs,
  pkgs,
  richenLib,
  ...
}:
{
  imports = [
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    inputs.hydenix.nixosModules.default
    inputs.hjem.nixosModules.default
    ./hardware-configuration.nix
    ./vfio
    ./drivers.nix
  ];
  hjem = {
    users.richen = {
      user = "richen";
      directory = "/home/richen";
      clobberFiles = true;
      files = {
        ".config/Code/User/settings.json" = {
          type = "copy";
          permissions = "0644";
          source = pkgs.writeText "vscode-settings.json" ''
             {
              "workbench.colorTheme": "Tokyo Night",
              "window.menuBarVisibility": "toggle",
              "editor.fontSize": 17,
              "editor.fontWeight": "700",
              "editor.lineHeight": 1.3,
              "editor.scrollbar.vertical": "hidden",
              "editor.scrollbar.verticalScrollbarSize": 0,
              "security.workspace.trust.untrustedFiles": "newWindow",
              "security.workspace.trust.startupPrompt": "never",
              "security.workspace.trust.enabled": false,
              "editor.minimap.side": "left",
              "editor.fontFamily": "'GohuFont uni14 Nerd Font Propo'",
              "extensions.autoUpdate": true,
              "workbench.statusBar.visible": true,
              "terminal.external.linuxExec": "kitty",
              "terminal.explorerKind": "both",
              "terminal.sourceControlRepositoriesKind": "both",
              "telemetry.telemetryLevel": "off",
              "workbench.activityBar.location": "top",
              "window.customTitleBarVisibility": "auto",
              "workbench.iconTheme": "catppuccin-mocha",
              "editor.cursorSmoothCaretAnimation": "on",
              "editor.autoIndent": "full",
              "editor.formatOnSave": true,
              "nix.enableLanguageServer": true,
              "nix.formatterPath": "nixfmt",
              "nix.serverPath": "nil",
              "nix.hiddenLanguageServerErrors": [
                "textDocument/definition",
                "textDocument/formatting",
                "textDocument/documentSymbol"
              ],
              "nix.serverSettings": {
                "nil": {
                  "formatting": {
                    "command": ["nixfmt"]
                  }
                }
              },
              "workbench.sideBar.location": "right",
              "git.enableSmartCommit": true,
              "github.copilot.nextEditSuggestions.enabled": true,
              "todo-tree.general.tags": [
                "BUG",
                "HACK",
                "FIXME",
                "TODO",
                "XXX",
                "[ ]",
                "[x]",
                "todo",
                "fixme",
                "bug"
              ],
              "editor.minimap.enabled": false
            }
          '';
        };
      };
    };
  };

  # editor
  programs.vscode = {
    enable = true;
    extensions = [
      pkgs.vscode-extensions.aaron-bond.better-comments
      pkgs.vscode-extensions.bierner.markdown-preview-github-styles
      pkgs.vscode-extensions.catppuccin.catppuccin-vsc-icons
      pkgs.vscode-extensions.davidanson.vscode-markdownlint
      pkgs.vscode-extensions.dbaeumer.vscode-eslint
      pkgs.vscode-extensions.ecmel.vscode-html-css
      pkgs.vscode-extensions.enkia.tokyo-night
      pkgs.vscode-extensions.esbenp.prettier-vscode
      pkgs.vscode-extensions.geequlim.godot-tools
      pkgs.vscode-extensions.github.copilot
      pkgs.vscode-extensions.github.vscode-github-actions
      pkgs.vscode-extensions.github.vscode-pull-request-github
      pkgs.vscode-extensions.ibm.output-colorizer
      pkgs.vscode-extensions.jnoortheen.nix-ide
      pkgs.vscode-extensions.leonardssh.vscord
      pkgs.vscode-extensions.mads-hartmann.bash-ide-vscode
      pkgs.vscode-extensions.mkhl.shfmt
      pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
      pkgs.vscode-extensions.redhat.vscode-yaml
      pkgs.vscode-extensions.tamasfe.even-better-toml
      pkgs.vscode-extensions.timonwong.shellcheck
      pkgs.vscode-extensions.yoavbls.pretty-ts-errors
      pkgs.vscode-extensions.yzhang.markdown-all-in-one
      pkgs.vscode-extensions.ziglang.vscode-zig
      pkgs.vscode-extensions.gruntfuggly.todo-tree
      pkgs.vscode-extensions.rooveterinaryinc.roo-cline
    ];
  };

  networking.hostName = "fern";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users."richen" =
      { config, ... }:
      {
        imports = [
          inputs.hydenix.homeModules.default
          ../../modules/hydenix.nix
        ];

        desktops.hydenix = {
          enable = true;
          hostname = "fern";
        };

        home.stateVersion = "25.05";
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
    richenLib.wrappers.kitty
    pkgs.mangohud
  ];

  hydenix = {
    enable = true;
    hostname = "fern";
    timezone = "America/Vancouver";
    locale = "en_CA.UTF-8";
  };

  users.users.richen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
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

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      protontricks.enable = true;
    };
  };

  networking.interfaces.enp7s0.wakeOnLan.enable = true;

  # TODO: make swap module for fern
  swapDevices = [
    {
      device = "/swapfile";
      size = 96 * 1024;
    }
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/f3573fb1-5c09-4c7a-b3d4-ef0e73ad547f";
  boot.kernelParams = [
    "resume_offset=67471360"

    # TODO: this and below are for gaming performance
    "mitigations=off" # Small performance boost, zen kernel handles this well
  ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # CPU scaling settings
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
    powertop.enable = false;
  };

  # todo: fern: review below kernel sysctls
  boot.kernel.sysctl = {
    "vm.swappiness" = 1; # Minimize swap usage for gaming
    "vm.overcommit_memory" = 2; # Prevent memory overcommit
    "vm.dirty_ratio" = 5; # Better memory management
    "vm.dirty_background_ratio" = 2; # Background writeback threshold
  };

  hydenix.boot.enable = false;

  boot = {
    plymouth.enable = true;
    kernelPackages = pkgs.lib.mkForce pkgs.linuxPackages_6_12;
    loader.systemd-boot.enable = pkgs.lib.mkForce false;
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
        extraEntries = ''
          menuentry "UEFI Firmware Settings" {
            fwsetup
          }
        '';
      };
    };
    kernelModules = [
      "v4l2loopback"
    ];
    extraModprobeConfig = ''
      options v4l2loopback devices=2 video_nr=1,2 card_label="OBS Cam, Virt Cam" exclusive_caps=1
    '';
  };

  system.stateVersion = pkgs.lib.mkDefault "26.05";
}
