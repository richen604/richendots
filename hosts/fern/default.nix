{
  pkgs,
  ...
}:
let
  chromeWebStoreUpdateUrl = "https://clients2.google.com/service/update2/crx";
  chromiumExtensionCrxUrl = id: "${chromeWebStoreUpdateUrl}?response=redirect&acceptformat=crx2,crx3&prodversion=150.0.7871.114&x=id%3D${id}%26installsource%3Dondemand%26uc";
  chromiumExtensions =
    let
      extensions = [
        {
          id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
          version = "1.72.2";
          hash = "1y2niclds5sshmd7sha2ci1fa0w4sb3zjcdm473ywsg5vkkdh0kf";
        }
        {
          id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
          version = "4.9.128";
          hash = "0lwamw0dmjvjjvcidsy2cmrh7azmbjgdrm6wm5ljlpirag0f5bg3";
        }
        {
          id = "oboonakemofpalcgghocfoadofidjkkk";
          version = "1.10.3";
          hash = "0999087b26m0s8g2nznbzjdhbbyqzpzidvcafakrj3c3v1x00sf2";
        }
        {
          id = "mnjggcdmjocbbbhaepdhchncahnbgone";
          version = "6.1.6";
          hash = "1zxlrlvggis8zhyydmmnwmg5qxbawzpwdryxl0f10ilrd8mzx1sm";
        }
        {
          id = "hfjbmagddngcpeloejdejnfgbamkjaeg";
          version = "2.12.2";
          hash = "08q44nr70dg7x5mpmh7gj9cyv7i8q57k9icmg0hy5308whgqnj6n";
        }
      ];
    in
    pkgs.runCommand "chromium-local-extensions" { } ''
      mkdir -p $out/share/chromium/extensions $out/share/chromium/crx
      ${pkgs.lib.concatMapStringsSep "\n" (extension: ''
        cp ${
          pkgs.fetchurl {
            name = "${extension.id}.crx";
            url = chromiumExtensionCrxUrl extension.id;
            sha256 = extension.hash;
          }
        } $out/share/chromium/crx/${extension.id}.crx
        printf '{"external_crx":"%s","external_version":"${extension.version}"}\n' \
          "$out/share/chromium/crx/${extension.id}.crx" \
          > $out/share/chromium/extensions/${extension.id}.json
      '') extensions}
    '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./drivers.nix
    ../../modules/sunshine
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/newdev/richendots";
  };

  environment.systemPackages = [
    chromiumExtensions
  ];
  environment.pathsToLink = [
    "/share/chromium/extensions"
    "/share/chromium/crx"
  ];

  programs.chromium = {
    enable = true;
    extraOpts = {
      BrowserSignin = 0;
      SyncDisabled = true;
      PasswordManagerEnabled = false;
      BackgroundModeEnabled = false;
    };
  };

  environment.etc."chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text =
    builtins.toJSON {
      name = "org.keepassxc.keepassxc_browser";
      description = "KeePassXC integration with native messaging support";
      path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
      ];
    };

  networking.interfaces.enp5s0.wakeOnLan.enable = true;

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

    # gaming performance
    "mitigations=off"
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

  services.nixpull = {
    enable = true;
    role = "client";
    server.user = "richen";
    notify = {
      enable = true;
      users = [ "richen" ];
    };
  };

  system.stateVersion = pkgs.lib.mkDefault "26.05";
}
