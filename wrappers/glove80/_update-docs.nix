{
  inputs,
  pkgs,
  ...
}:

pkgs.writeShellApplication {
  name = "glove80-update-docs";
  runtimeInputs = with pkgs; [
    coreutils
    python3
  ];
  text = ''
    target=$PWD/wrappers/glove80
    if [ ! -f "$target/preferences.json" ]; then
      printf 'run this from the richendots repository root\n' >&2
      exit 1
    fi

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT

    python ${./customize.py} --summary \
      ${./preferences.json} \
      ${inputs.glorious-engrammer}/keymap.zmk \
      "$work/keymappings.md"

    install -m 0644 "$work/keymappings.md" "$target/keymappings.md"
    install -m 0644 \
      ${inputs.glorious-engrammer}/README/all-layer-diagrams.pdf \
      "$target/all-layer-diagrams.pdf"

    printf 'updated %s and %s\n' \
      "$target/keymappings.md" \
      "$target/all-layer-diagrams.pdf"
  '';
  meta.description = "Update checked-in Glove80 mapping documentation";
}
