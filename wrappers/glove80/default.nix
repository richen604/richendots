{
  inputs,
  pkgs,
  ...
}:

let
  keymap = pkgs.runCommand "glove80-keymap" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    mkdir -p work $out
    cp ${inputs.glorious-engrammer}/keymap.zmk work/glove80.keymap
    chmod u+w work/glove80.keymap

    python ${./customize.py} ${./preferences.json} work/glove80.keymap $out/glove80.keymap
    python ${./customize.py} ${./preferences.json} $out/glove80.keymap work/idempotence.keymap
    cmp $out/glove80.keymap work/idempotence.keymap
  '';

  # pr36 still uses a couple of old nixpkgs names.
  moergoPkgs = pkgs.extend (
    _final: prev: {
      runCommandNoCC = prev.runCommand;
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pythonFinal: _pythonPrev: { can = pythonFinal.python-can; })
      ];
    }
  );
  moergo = import inputs.glove80-zmk { pkgs = moergoPkgs; };
  config = {
    keymap = "${keymap}/glove80.keymap";
    kconfig = ./glove80.conf;
  };
  left = moergo.zmk.override (config // { board = "glove80_lh"; });
  right = moergo.zmk.override (config // { board = "glove80_rh"; });
  firmware = (moergo.combine_uf2 left right "glove80").overrideAttrs {
    name = "glove80-firmware";
  };
  updateDocs = pkgs.callPackage ./_update-docs.nix { inherit inputs; };
  # make nix run behave like a build and refresh the nearby maps.
  runGlove80 = pkgs.writeShellApplication {
    name = "glove80";
    runtimeInputs = [
      pkgs.coreutils
      updateDocs
    ];
    text = ''
      glove80-update-docs

      if [ -e "$PWD/result" ] && [ ! -L "$PWD/result" ]; then
        printf 'refusing to replace non-symlink: %s/result\n' "$PWD" >&2
        exit 1
      fi

      ln -sfn ${firmware} "$PWD/result"
      printf 'firmware: %s/result/glove80.uf2\n' "$PWD"
    '';
  };
in
pkgs.symlinkJoin {
  name = "glove80";
  paths = [
    firmware
    runGlove80
  ];
  meta = {
    description = "Glove80 firmware with QWERTY as the primary layer";
    mainProgram = "glove80";
  };
}
