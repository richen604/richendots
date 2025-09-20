# Systemd Journal Error Todo List

- feat(gpu): Investigate AMD GPU Errors
  - [ ] Check for newer `linux-firmware` or known issues with `amdgpu` on kernel `6.16.3-zen1`.
  - [ ] Address `psp reg wait timed out` errors.
  - [ ] Address `SMU driver if version not matched` error.

- fix(filesystem): Resolve Filesystem Corruption Warnings
  - [ ] Address `The disk contains an unclean file system` and `Volume was not properly unmounted` messages on NTFS and FAT partitions.
  - [ ] Boot into Windows to disable "Fast Startup" and run `chkdsk`.

- feat(kernel): Add Missing Kernel Module
  - [ ] Add `v4l2loopback` kernel module package to NixOS configuration.

- fix(sddm): Fix SDDM Login Manager Theme
  - [ ] Add `QtQuick.VirtualKeyboard.Plugins` dependency.
  - [ ] Investigate and fix QML assignment errors (`Unable to assign [undefined] to QQuickItem*`).

- fix(polkit): Address Polkit and Permission Errors
  - [ ] Check Polkit configuration and file permissions for `Error opening rules directory`.

- fix(home-manager): Fix Home Manager Script Errors
  - [ ] Add `coreutils` (for `mkdir` and `date`) to `obsidian-todo-linker` script's environment.
  - [ ] Investigate why `hyde-config` is receiving empty TOML content.

- fix(syncthing): Resolve Syncthing Warning
  - [ ] Check integrity of "KeePass Database" folder and potentially recreate the folder marker.

- fix(pam): Address PAM SSH Agent Authentication Failure
- feat(obs): add plugins
  Context: This TODO is found in `modules/hm/common/obs.nix`. It suggests adding more plugins to OBS, listing examples like source record, obs advanced masks, source clone, move transition, and background blur.

- fix(obs): contribute to hypr-obs-mouse-follow script (toggle, feature parity with alternatives)
  Context: This TODO is found in `modules/hm/common/obs.nix`. It suggests contributing to the `hypr-obs-mouse-follow` script to add toggle functionality and achieve feature parity with alternatives.

- feat(obs): add scenes to obs module for declarative configuration
  Context: This TODO is found in `modules/hm/common/obs.nix`. It suggests adding declarative scene configuration to the OBS module, possibly as an option for use in other hosts.

- refactor(hydenix): use config.hostname and remove assertions
  Context: This FIXME is found in `modules/hm/desktops/hydenix.nix`. It suggests that the `config.hostname` should be used directly and assertions should be removed.

- chore(hydenix): update private module info
  Context: This FIXME is found in `modules/hm/desktops/hydenix.nix`. It indicates that information related to a private module needs to be changed.

- feat(obsidian): add backup methods
  Context: This TODO is found in `modules/hm/users/richen/obsidian.nix`. It suggests adding backup methods for Obsidian.

- refactor(system): move polkit rule for udisks2
  Context: This TODO is found in `modules/system/common/default.nix`. It suggests moving the `polkit.addRule` for `udisks2` permissions to a more appropriate location.

- fix(system): address general system issues
  Context: This TODO is found in `modules/system/common/default.nix`. It's a general note to fix issues later.

- refactor(reboot): move grub-reboot script now that it works
  Context: This TODO is found in `modules/system/common/default.nix`. It suggests fixing the `reboot-to` script and moving it to a different location.

- feat(fern): create swap module
  Context: This TODO is found in `modules/system/hosts/fern/default.nix`. It suggests creating a dedicated swap module for the 'fern' host.

- perf(fern): optimize for gaming performance
  Context: This TODO is found in `modules/system/hosts/fern/default.nix`. It indicates that the kernel parameters `mitigations=off` and others are for gaming performance.

- refactor(vfio): make module more generic and extendable
  Context: This TODO is found in `modules/system/hosts/fern/vfio/default.nix`. It suggests making the VFIO module more generic, extendable, and moving it to a common location.

- fix(vfio): figure out the prepare script
  Context: This TODO is found in `modules/system/hosts/fern/vfio/default.nix`. It indicates a need to figure out the prepare script for libvirt hooks.

- feat(vfio): implement nvidia driver check and setup for nixos
  Context: This TODO is found in `modules/system/hosts/fern/vfio/scripts/start-vfio.sh`. It suggests implementing NVIDIA driver checks and VFIO setup specifically for NixOS.

- fix(vfio): implement nvidia driver reattachment and cleanup for nixos
  Context: This TODO is found in `modules/system/hosts/fern/vfio/scripts/stop-vfio.sh`. It suggests implementing NVIDIA driver reattachment and VFIO cleanup specifically for NixOS.

- feat(oak): enable after install
  Context: This TODO is found in `modules/system/hosts/oak/default.nix`. It suggests that a feature should be enabled after installation.

## future

- hydenix: some yubikey touch detection for hyprlock and waybar <https://github.com/maximbaz/yubikey-touch-detector>
- hydenix: rofi theme for browser search using unduck shebang
- better docs outlining my system setup
- neovim setup for astronvim
- tmux? <https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file> also looks cool
- firmware for glove80 <https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix>
- vscode-server
- declarative cursor extensions / settings
- cursor fhs
- make cursor look better? idk
- obsidian:
  - make it look like this (feeds?) <https://github.com/glanceapp/glance>
  - declarative plugins? (just symlink folder idk)
