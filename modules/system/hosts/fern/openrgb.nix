{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.fern.openrgb;

  no-rgb = pkgs.writeScriptBin "no-rgb" ''
    #!/bin/sh
    NUM_DEVICES=$(${pkgs.openrgb}/bin/openrgb --noautoconnect --list-devices | grep -E '^[0-9]+: ' | wc -l)

    for i in $(seq 0 $(($NUM_DEVICES - 1))); do
      ${pkgs.openrgb}/bin/openrgb --noautoconnect --device $i --mode static --color 000000
    done
  '';
in
{
  options.modules.fern.openrgb = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OpenRGB for controlling RGB lighting";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hardware.openrgb.enable = true;
    # Install OpenRGB package
    environment.systemPackages = with pkgs; [
      openrgb-with-all-plugins
    ];

    # Add udev rules for OpenRGB to access devices without root
    services.udev.extraRules = ''
      # OpenRGB udev rules to allow access to RGB devices
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1532", TAG+="uaccess" # Razer
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2516", TAG+="uaccess" # Cooler Master
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0c70", TAG+="uaccess" # Corsair
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1b1c", TAG+="uaccess" # Corsair
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="7b5", TAG+="uaccess"  # ASUS
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1044", TAG+="uaccess" # Gigabyte
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="048d", TAG+="uaccess" # MSI
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="8087", TAG+="uaccess" # Intel
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", TAG+="uaccess" # ST Microelectronics
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="2433", TAG+="uaccess" # NZXT
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="195d", TAG+="uaccess" # DeepCool
    '';

    services.udev.packages = [ pkgs.openrgb ];
    boot.kernelModules = [
      "i2c-dev"
      "i2c-piix4"
    ];
    hardware.i2c.enable = true;

    systemd.services.no-rgb = {
      description = "no-rgb";
      serviceConfig = {
        ExecStart = "${no-rgb}/bin/no-rgb";
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
