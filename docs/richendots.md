---
tags:
  - project/richendots-private
---

## now

- [ ] fix: dolphin doesnt grab default programs, shows 0 programs
- [ ] kde connect doesnt work
- [ ] feat: fern - maybe drop vfio?
- [ ] feat: use xdg-desktop-portal-hyprland as it has a good chooser
- [ ] fix: git doesnt set the default user, is my git wrapper working?
- [ ] fix: media playing should prevent idle
- [ ] feat: run sunshine on startup
- [ ] refactor to use [nosh](https://codeberg.org/poacher/nosh/src/branch/main)
  - feature/\* based modules, not profiles
  - make modules more modular
  - add nosh for private repo

## next

- [ ] feat: limine secure boot
- [ ] feat: disko configurations + luks
- [ ] feat: nixos-anywhere support + dev-shell

## backlog

- [ ] firmware for glove80 <https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix>
- [ ] green vscode theme that doesn't look like garbage
- [ ] theme obsidian
- [ ] systemd services for all autostart apps
- [ ] obsidian:
  - [ ] make it look like this (feeds?) <https://github.com/glanceapp/glance>
  - [ ] declarative plugins?
- [ ] keepass does not start on boot, windowrule to open it center on fern and oak
- [ ] screenshot should freeze screen
- [ ] fern: plymouth aligned weird
- [ ] fern: monitor alignment is slightly off for left and right
- [ ] anti-idler waybar button?

## future

- [ ] keepassxc: not sure if config actually works
- [ ] wrap:
  - [ ] nvim with mnw
  - [ ] tmux
    - <https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file> also looks cool
  - [ ] mpv
  - [ ] wlogout
  - [ ] yazi
- [ ] clean up flake.nix
- [ ] global color palette, grove.css to nix
- [ ] firefox: wrapper should be private
- [ ] firefox: migrate password manager fully, migrate from sync
- [ ] firefox: <https://codeberg.org/librewolf/settings/src/branch/master/librewolf.cfg>
  - cfg should be a separate file import for better viewing
  - remove options for RFP, webgl,
  - remove "startup.homepage\_\*
- [ ] vicinae: add extensions support for vicinae wrapper
- [ ] keybinds menu with vicinae?
- [ ] some qol scripts / menus for vicinae
- [ ] npins & a post flake world?

## nixpull

- [ ] rewrite, keep bash tho
- [ ] more robust api, feature agnostic, easily customizable
- [ ] full nix module impl
- [ ] pre post etc hooks
- [ ] channels? clients determine branch of build using git
- [ ] build history, hold multiple builds
- [ ] git worktrees integration
- [ ] inotify
- [ ] better metadata
  - host
  - called
  - nixpkgs version
  - channel (?)
  - human readable timestamp
  - git rev
  - timestamp
- [ ] auto rollback similar to deployrs
- [ ] activation options, `nixpull client test` etc
- [ ] `nh` support
- [ ] fix systemd implementation of activation

## references

- yubikey <https://wiki.nixos.org/wiki/Yubikey>
- hardening, disko, luks, etc <https://tsawyer87.github.io/posts/hardening_nixos/>
