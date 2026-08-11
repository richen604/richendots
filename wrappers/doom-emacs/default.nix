# nix-doom-emacs-unstraightened normally uses ifd to discover doom packages at eval time.
# keep system eval ifd-free by using a local adapter with a tracked generated manifest.
{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  doomInput = inputs.nix-doom-emacs-unstraightened;
  doomTheme = import ./_theme.nix { inherit (richenLib) theme; };
  generatedTheme = pkgs.replaceVars ./doom.d/themes/grove-theme.el doomTheme.replacements;
  generatedDoomDir = pkgs.runCommandLocal "doom.d-${richenLib.theme.name}" { } ''
    cp -r ${./doom.d} $out
    chmod -R u+w $out
    cp ${generatedTheme} $out/themes/grove-theme.el
  '';
  updateIntermediates = pkgs.callPackage (doomInput + "/build-helpers/doomscript.nix") {
    name = "doom-intermediates";
    doomSource = doomInput.inputs.doomemacs;
    emacs = pkgs.emacs-nox;
    extraArgs = {
      DOOMDIR = "${./doom.d}";
    };
    script = doomInput + "/build-helpers/dump";
    scriptArgs = "-m ${doomInput.inputs.doomemacs-modules} -u ${doomInput}/doom-module -o $out";
  };
  updateScript = pkgs.writeShellApplication {
    name = "update-doom-emacs-generated";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.nix
    ];
    text = ''
      repo="''${1:-}"
      if [[ -z "$repo" ]]; then
        repo="$(git rev-parse --show-toplevel)"
      fi

      if ! git -C "$repo" diff --quiet -- wrappers/doom-emacs/doom.d; then
        printf 'stage or commit wrappers/doom-emacs/doom.d changes before regenerating doom metadata\n' >&2
        exit 1
      fi

      out="$(nix build "$repo#doom-emacs.updateIntermediates" --print-out-paths --option allow-import-from-derivation false)"
      install -m 0644 "$out/packages.json" "$repo/wrappers/doom-emacs/generated/packages.json"
      install -m 0644 "$out/packages.el" "$repo/wrappers/doom-emacs/generated/packages.el"
    '';
  };
  doomPackages = pkgs.callPackage ./_no-ifd.nix {
    doomDir = generatedDoomDir;
    doomIntermediates = ./generated;
    doomLocalDir = "~/.local/share/nix-doom";
    doomSource = doomInput.inputs.doomemacs;
    doomModules = doomInput.inputs.doomemacs-modules;
    unstraightenedSource = doomInput;
    emacs = pkgs.emacs-nox;
    inherit (pkgs) emacsPackagesFor;
    experimentalFetchTree = true;
    toInit = _lib: _attrs: "";
    extraBinPackages = [
      pkgs.git
      pkgs.fd
      pkgs.ripgrep
      pkgs.nil
      pkgs.nixfmt
      pkgs.nodejs
      pkgs.typescript-language-server
      pkgs.vscode-langservers-extracted
      pkgs.yaml-language-server
    ];
    extraPackages = epkgs: [
      (epkgs.treesit-grammars.with-grammars (
        grammars: with grammars; [
          tree-sitter-bash
          tree-sitter-css
          tree-sitter-html
          tree-sitter-javascript
          tree-sitter-jsdoc
          tree-sitter-json
          tree-sitter-markdown
          tree-sitter-markdown-inline
          tree-sitter-nix
          (tree-sitter-tsx.override { location = "tsx"; })
          tree-sitter-typescript
          tree-sitter-yaml
        ]
      ))
    ];
  };
in
doomPackages.emacsWithDoom.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit updateIntermediates updateScript;
  };
})
