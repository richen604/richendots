<img align="right" width="55px" src="https://em-content.zobj.net/source/apple/419/herb_1f33f.png"></img>

# richendots - the grove

my personal nixos config

---

![screenshot](./assets/screenshot.png)

---

#### features:

- flakes
- wrapped programs using [Lassulus/wrappers](https://github.com/Lassulus/wrappers)
- `4.66s` eval (on my machine)
- multi host & single user
- profiles (common, desktop, laptop, server)
- 5 hosts
  - fern - desktop 🌿
  - oak - laptop 🌳
  - cedar - server 🪵
  - willow - cloud vm 🌾
  - ivy - phone 🍃

> [!NOTE] note:
> some modules, packages, and options are obfuscated from private imports </br>
> the configuration will not build from a clone/fork without `inputs.richendots-private` removed from `./lib.nix`