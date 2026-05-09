---
tags:
  - project/richendots-private
---

# todo

## now

- [ ] fix: media playing should prevent idle

## next

- [ ] fix: media playing should prevent idle
- [ ] feat: nixos-anywhere support + dev-shell
- [ ] fix: git doesnt set the default user, is my git wrapper working?
- [ ] fix: dolphin doesnt grab default programs, shows 0 programs
- [ ] fix: kde connect doesnt work
- [ ] feat: richendots-private should inherit richendots inputs

## backlog

### developer experience

- [ ] fix: nvim plugins currently don't load declaratively and wrapped, install to .config
- [ ] feat: dec llm workflows using opencode and roo
- [ ] feat: wrap tmux
	- [ ] setup tmux, add plugins
	- https://www.reddit.com/r/AstroNvim/comments/10x45rm/wow_tmux_navigation_works_outofthebox/
	- christoomey/vim-tmux-navigator
	- tmux-plugins/tmux-yank
	- tmux-plugins/tmux-continuum
	- <https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file>
	- [ ] ressurect or eq
	- [ ] session along with panes
	- [ ] panes
	- [ ] tabs
	- [ ] good keybinds support with astronnvim
	- [ ] tmuxinator - mutable config ideally `export TMUXINATOR_CONFIG="$HOME/.config/tmuxinator:$HOME/.config/tmuxinator-nix"`?
		- tab auto open both opencode and opencode-web
		- tab for bare terminal
		- opencode web `OPENCODE_SERVER_PASSWORD=secret opencode web --mdns --mdns-domain oc-myproject.local`
		- sops that secret
		- tmuxinator template for new projects of various setups
		- how to handle godot? just run?
- [ ] some sort of project loader for tmux/nvim
	- combine tmuxinator with fzf or gum and a list of projects, ideally mutable
	- would have to be host dependant (fern gets a different list etc)
	- fetching projects tmuxinator is the loader. if tmux is wrapped ill have to grab the binary of tmuxinator in order to find the current nix store path. and merge two yaml files then process with jq fuck
- [ ] research: way to display cheat sheets for astronvim, nvim, tmux, glove80

### theming

- [ ] style: theme astronvim to grove theme
- [ ] grove zed theme that doesn't look like garbage
- [ ] zed settings with hjem
  - issue is that they use secrets for servers
- [ ] finish theming obsidian

### system polish

- [ ] systemd services for all autostart apps
- [ ] obsidian - declarative plugins?
- [ ] feat: screenshot should freeze screen
- [ ] fix: keepass does not start on boot, windowrule to open it center on fern and oak
- [ ] fern: fix: plymouth aligned weird
- [ ] fern: monitor alignment is slightly off for left and right
- [ ] feat: use new chooser for xdg-desktop-portal
- [ ] feat: firmware for glove80 <https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix>
- [ ] feat: limine secure boot
- [ ] feat: disko configurations + luks

### terminal & apps

- [ ] feat: port richenfox config to glide
- [ ] wrap:
  - [ ] mpv
  - [ ] wlogout
  - [ ] yazi

### firefox

- [ ] firefox: wrapper should be private
- [ ] firefox: migrate password manager fully, migrate from sync
- [ ] firefox: <https://codeberg.org/librewolf/settings/src/branch/master/librewolf.cfg>
  - cfg should be a separate file import for better viewing
  - remove options for RFP, webgl,
  - remove "startup.homepage\_\*

### architecture

- [ ] clean up flake.nix
- [ ] global color palette, grove.css to nix
- [ ] refactor to use [nosh](https://codeberg.org/poacher/nosh/src/branch/main)
  - feature/\* based modules alongside profiles. eg profiles/common/feature.nix
  - make modules more modular
  - add nosh for private repo
- [ ] npins & a post flake world?

### vicinae

- [ ] keybinds menu with vicinae?
- [ ] vicinae: add extensions support for vicinae wrapper
- [ ] some qol scripts / menus for vicinae

### keepass

- [ ] keepassxc: not sure if config actually works

## nixpull

- [ ] rewrite, keep bash tho
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
