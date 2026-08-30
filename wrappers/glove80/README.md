# glove80 firmware

this builds the glorious engrammer keymap with qwerty as the first layer. mouse
support and per-key rgb are enabled.

[`keymappings.md`](./keymappings.md) is a generated, searchable view of every
layer and physical key row. it is useful when planning ergonomic shortcuts
elsewhere in the fern config.

[`all-layer-diagrams.pdf`](./all-layer-diagrams.pdf) is the matching visual map
from glorious engrammer.

build the firmware and refresh both files with one command:

```sh
nix run .#glove80
```

the firmware will be at `result/glove80.uf2`.

## check first

```sh
nix run .#glove80-flash -- --check
```

this is read-only. it checks that fern can see both bootloader volumes. it does
not mount them or copy anything.

the script checks the right half first, then the left half. use one usb cable
and follow the prompts.

- right bootloader keys: `I + PgDn`
- left bootloader keys: `Magic + E`

turn the half off, hold both keys, turn it on, then release the keys.

## flash

connect and test a spare keyboard first. you will need it while the glove80 is
off.

```sh
nix run .#glove80-flash
```

the script pauses before every important step. it will:

1. flash the right half
2. wait for the right half to come back normally
3. flash the left half
4. wait for the left half to come back normally
5. walk through a factory reset of both halves

do not touch the power, cable, kvm, or usb switch while a file is being copied.
if a half disappears without coming back normally, the script stops instead of
guessing that the flash worked.

the factory reset is always included because this firmware uses the advanced
rgb setup. it resets the left half first, then the right half, and erases saved
bluetooth profiles.

## update

```sh
nix flake update glorious-engrammer glove80-zmk
nix run .#glove80
```

zmk cannot tell us which firmware version is already installed.

## flash Fern from Cedar

Run the Fern-only recovery workflow from Cedar when the Glove80 is unavailable
as an input device:

```sh
nix run .#glove80-flash-fern
```

The command refuses to run outside Cedar, hardcodes Fern as its SSH target,
builds on Fern, and only mounts uniquely detected `vfat` volumes labelled
`GLV80RHBOOT` or `GLV80LHBOOT`. Fern sudo authentication uses Cedar's forwarded
SSH agent. A read-only build and connectivity check is also available:

```sh
nix run .#glove80-flash-fern -- --check
```
