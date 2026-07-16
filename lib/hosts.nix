{
  inputs,
  lib,
  mkLib,
  pkgsFor,
}:
let
  hostVars = {
    fern = {
      hostname = "fern";
      system = "x86_64-linux";
      profile = "desktop";
      stateVersion = "26.05";
    };

    oak = {
      hostname = "oak";
      system = "x86_64-linux";
      profile = "laptop";
      stateVersion = "26.05";
    };

    cedar = {
      hostname = "cedar";
      system = "x86_64-linux";
      profile = "server";
      stateVersion = "25.05";
    };
  };

  mkHost =
    hostvars:
    let
      pkgs = pkgsFor hostvars.system;
      richenLib = mkLib pkgs;
      recursiveModules =
        dir:
        richenLib.lib.listFilesRecursiveCond dir (
          filename: lib.hasSuffix ".nix" filename && filename != "default.nix" && !lib.hasPrefix "_" filename
        );
    in
    lib.nixosSystem {
      inherit pkgs;
      system = hostvars.system;
      specialArgs = {
        inputs = inputs // inputs.richendots-private.inputs;
        hostname = hostvars.hostname;
        inherit richenLib hostvars;
      };

      modules =
        recursiveModules ../profiles/common
        ++ lib.optionals (hostvars.profile == "desktop" || hostvars.profile == "laptop") (
          recursiveModules ../profiles/gui
        )
        ++ recursiveModules ../profiles/${hostvars.profile}
        ++ recursiveModules ../hosts/${hostvars.hostname}
        ++ [ (inputs.richendots-private.nixosModules.${hostvars.hostname} or { }) ];
    };

  mkVm =
    hostvars:
    ((mkHost hostvars).extendModules {
      modules = [
        (
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            virtualisation.vmVariant = {
              virtualisation = {
                memorySize = 14096;
                cores = 4;
                diskSize = 10240;
                qemu.options = [
                  "-device virtio-vga-gl"
                  "-display gtk,gl=on,grab-on-hover=on"
                  "-usb -device usb-tablet"
                  "-cpu host"
                  "-enable-kvm"
                  "-machine q35"
                  "-device intel-iommu"
                  "-device ich9-intel-hda"
                  "-device hda-output"
                  "-vga none"
                ];
              };
              services.xserver.videoDrivers = [
                "virtio"
              ];
            };

            environment.variables.WLR_NO_HARDWARE_CURSORS = "1";

            virtualisation.libvirtd.enable = true;
            environment.systemPackages = with pkgs; [
              open-vm-tools
              spice-gtk
              spice-vdagent
              spice
            ];
            services.qemuGuest.enable = true;
            services.spice-vdagentd.enable = true;
            hardware.graphics.enable = true;
          }
        )
      ];
    }).config.system.build.vm;
in
{
  inherit hostVars mkHost mkVm;

  nixosConfigurations = lib.mapAttrs (_host: mkHost) hostVars;
}
