# TODO

- [ ] multi system for other hosts (laptop, desktop, vm, install liveusbs, etc) Host naming scheme:

- 🌿 Desktop: fern
- 🌳 Laptop: oak
- 🌲 Media: pine
- 🪵 Server: cedar
- 🌱 Live USB OS: sapling
- 🍀 Main VM: clover
- Install USBs: [hostname]-seed (fern-seed, oak-seed, cedar-seed)
- VMs: [hostname]-vm (fern-vm, oak-vm, cedar-vm)

- [ ] pam-rssh
- [ ] vscode-server
- [ ] declarative cursor extensions / settings
- [ ] cursor fhs
- [ ] auto gc (with nh)
- [ ] make cursor look better? idk
- [ ] obsidian:
  - [ ] make it look like this (feeds?) https://github.com/glanceapp/glance
  - [ ] declarative plugins? (just symlink folder idk)

## future

- [ ] <https://wiki.archlinux.org/title/Hardware_video_acceleration> setup hardware acceleration forgor to do this
- [ ] hydenix: some yubikey touch detection for hyprlock and waybar <https://github.com/maximbaz/yubikey-touch-detector>
- [ ] hydenix: rofi theme for browser search using unduck shebang
- [ ] better docs outlining my system setup
- [ ] neovim setup for astronvim
- [ ] tmux? https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file also looks cool
- [ ] firmware for glove80 https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix
- [ ] disko
- [ ] new desktop setup?
  Focusing on modularity and ease of use.
  Users will have the ability to swap themes at runtime.
  Users will have the ability to eject any module of any theme with the manager
  users will have the ability to extend any theme with their own modules
  themes will be fully self contained will a well documented api and helper scripts
  built in nixos and home-manager
  possible to be multi-system with home-manager
  possible for themes to be multi-wm
  - main wm: hyprland
  - global theming guide, centralized imports in .config folder. whatever you want in .local folders
  - global theme helpers
    - symlink manager for runtime files
    - font management
    - gtk management
    - qt management
    - program modules
      - color backends:
        - main manager for all backends
        - helwall
        - pywal
        - matugen
        - base16?
      - bar:
        - ags
      - notification daemon:
        - swaync
      - lockscreen:
        - hyprlock
      - wallpaper:
        - swww
      - terminal:
        - kitty
      - file manager:
        - dolphin
      - browser:
        - firefox
      - media:
        - mpv
      - chat:
        - discord
        - element
        - signal
        - telegram
        - whatsapp
      - music:
        - spotify
      - calendar:
        - khal
      - shell:
        - zsh
        - tmux
        - neovim
        - vim
        - fastfetch
  - clean initial theme
  - references
    main: <https://www.reddit.com/r/unixporn/comments/1j77ml6/gnome_i_am_back_but_no_one_noticed/>
    <https://www.reddit.com/r/unixporn/comments/1jk9z4k/oc_i_created_hellwal_colorscheme_for_vim_nvim/>
    <https://www.reddit.com/r/unixporn/comments/1j40med/bspwm_and_again_my_rice/>
    <https://www.reddit.com/r/unixporn/comments/1jovga3/gnome_my_simple_setup/>
    <https://www.reddit.com/r/unixporn/comments/1j9omuu/sway_moved_from_hyprland/>
    <https://github.com/gh0stzk/dotfiles>
  - dumb packages
    - https://www.one-tab.com/page/PyGYWJTfSjytryvQx2L6kQ 