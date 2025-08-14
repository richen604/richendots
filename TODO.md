# TODO

## now

## next

## backlog

- docs(vm): add note about skipping login for sddm
  Context: This comment is found in `hosts/vm.nix`. It suggests that the user can set this option to skip login for sddm.

- feat(obsidian): make obsidian.nix work on any host
  Context: This TODO is found in `hosts/fern/default.nix` and `hosts/oak/default.nix`. It indicates a need to generalize the obsidian.nix module.

- refactor(nixos): move grub configuration to a dedicated module
  Context: This TODO is found in `hosts/oak/default.nix`. It suggests that the GRUB configuration for high-DPI display should be moved to a separate module for better organization.

- chore(flake): define flake path for oak
  Context: This TODO is found in `hosts/oak/default.nix`. It indicates that the flake path for the 'oak' host needs to be defined.

- fix(easyeffects): adjust output volume higher for voice
  Context: This TODO is found in `modules/hm/common/easyeffects.nix`. It suggests a fix for the output volume in EasyEffects for voice.

- feat(git): integrate with git-timeshift project
  Context: This TODO is found in `modules/hm/common/git.nix`. It indicates that the `git-picker` script will eventually be part of a `git-timeshift` project.

- feat(kde-connect): setup auto clipboard on android phone
  Context: This TODO is found in `modules/hm/common/kde-connect.nix`. It suggests setting up auto clipboard functionality on an Android phone, with a reference to an Ask Ubuntu link.

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