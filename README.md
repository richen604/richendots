<img align="right" width="55px" src="https://em-content.zobj.net/source/apple/419/herb_1f33f.png"></img>

# richendots - the grove

my personal nixos config

---

![screenshot](./assets/screenshot.png)

---

- **bar** - `waybar`
- **app launcher / clipboard** - `vicinae`
- **firefox theme** - tweaked `textfox`
- **spotify** - `spicetify-tui`
- **discord** - `equibop` + grove theme
- **file manager** - `yazi`
- **editor** - `doom emacs`
- **terminal** - `kitty`
- **shell** - `zsh`
- **notifications** - `swaync`
- **cursor** - `Bibata-Modern-Ice`
- **font** - `GohuFont Nerd Font`
- **gtk** - `catppuccin-mocha-green-compact`
- **icon** - `Papirus Dark`

## features

- flakes
- `3.7s` eval (on my machine)
- no-IFD Doom Emacs
- multi host & single user
- profiles (common, desktop, laptop, server)
- 3 hosts
  - fern - desktop 🌿
  - oak - laptop 🌳
  - cedar - server 🪵

> [!TIP]
> some modules, packages, and options are obfuscated from private imports </br>
> the configuration will not build from a clone/fork without `inputs.richendots-private` removed from `./lib/default.nix`

## license

MIT unless otherwise noted. See [`THIRD_PARTY_LICENSES.md`](./THIRD_PARTY_LICENSES.md) for third-party license exceptions.
