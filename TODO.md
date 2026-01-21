# todo

## now

- baseVars, hostVars init
- hosts/profiles init
- expand profiles impl
- refactor wrappers folder
  - modules vs impl
  - modules don't set wrapper by default allowing extensibility
  - some sort of recursive imports impl https://github.com/NixOS/nixpkgs/pull/481379/files

## next

- add priv modules
- clean up flake.nix
- break out mangowc into extendable configurations per host (fern/oak)

wrap:

- nvim with mnw
- tmux
- swaylock
- hypridle?
- mpv

## future

- more runtime packages for required applications w/ las wrappers
- disko configurations
- nixos-anywhere support + dev-shell
- npins & a post flake world
- add extensions support for vicinae wrapper
- better docs outlining my system setup
- keybinds menu with vicinae?
- neovim setup
- tmux? <https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file> also looks cool
- firmware for glove80 <https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix>
- obsidian:
  - make it look like this (feeds?) <https://github.com/glanceapp/glance>
  - declarative plugins?
wrap:
- kvantum
- dolphin
- spotify + sleek flatpak
