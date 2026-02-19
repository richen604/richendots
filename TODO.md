# todo

## now

- theme spicetify tui, copy full css and config for hjem usage. update spicetify tui for this

## next

- my custom scripts should also be packages for easier dev

## backlog

- keepass does not start on boot, windowrule to open it center on fern and oak
- screenshot should freeze screen
- satty shouldnt notify
- fern: kvm switch messes up monitor dp-* and mango does not support monitor id's i believe
- fern: plymouth does not run, even with vfio.nix off
- fern: monitor alignment is slightly off for left and right
- anti-idler waybar button? and media playing prevent idle
- bluetooth tray does not open devices on click

## future

- keepassxc: not sure if config actually works
- fern: right monitor needs to start on tag 3, center tag 2
- wrap:
  - nvim with mnw
  - tmux
  - mpv
  - wlogout
  - yazi
- clean up flake.nix
- global color palette, wall.css to nix
- firefox: wrapper should be private
- firefox: migrate password manager fully, migrate from sync 
- firefox: <https://codeberg.org/librewolf/settings/src/branch/master/librewolf.cfg> 
  - cfg should be a separate file import for better viewing
  - remove options for RFP, webgl, 
  - remove "startup.homepage_*
- disko configurations
- limine secure boot
- nixos-anywhere support + dev-shell
- vicinae: add extensions support for vicinae wrapper
- keybinds menu with vicinae?
- tmux? <https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file> also looks cool
- firmware for glove80 <https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix>
- obsidian:
  - make it look like this (feeds?) <https://github.com/glanceapp/glance>
  - declarative plugins?
- improve spicetify flatpak (config with hjem + declarative flatpak?)
- spicetify color palette
- green vscode theme that doesn't look like garbage
- some qol scripts / menus for vicinae
- npins & a post flake world?

## nixpull

- rewrite, not bash
- sqlite state store
- more robust api, feature agnostic, easily customizable
- non-nixos targets?
- full nix module impl
- pre post etc hooks
- channels? clients determine branch of build using git
- git worktrees integration
- inotify
- better metadata
  - host
  - called
  - nixpkgs version
  - channel (?)
  - human readable timestamp
  - git rev
- auto rollback similar to deployrs
- activation options, `nixpull client test` etc
- `nh` support
- fix systemd implementation of activation

## references

- <https://wiki.nixos.org/wiki/Yubikey>
