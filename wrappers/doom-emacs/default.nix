# nix-doom-emacs-unstraightened normally uses ifd to discover doom packages at eval time.
# keep system eval ifd-free by using a local adapter with a tracked generated manifest.
{
  inputs,
  pkgs,
  ...
}:
let
  doomInput = inputs.nix-doom-emacs-unstraightened;
  emacsOverlay = doomInput.inputs.emacs-overlay.overlays.package { } pkgs;
  updateIntermediates = pkgs.callPackage (doomInput + "/build-helpers/doomscript.nix") {
    name = "doom-intermediates";
    doomSource = doomInput.inputs.doomemacs;
    emacs = pkgs.emacs-nox;
    extraArgs = {
      DOOMDIR = "${./doom.d}";
    };
    script = doomInput + "/build-helpers/dump";
    scriptArgs = "-m ${doomInput.inputs.doomemacs-modules} -o $out";
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
    doomDir = ./doom.d;
    doomIntermediates = ./generated;
    doomLocalDir = "~/.local/share/nix-doom";
    doomSource = doomInput.inputs.doomemacs;
    doomModules = doomInput.inputs.doomemacs-modules;
    unstraightenedSource = doomInput;
    emacs = pkgs.emacs-nox;
    emacsPackagesFor = emacsOverlay.emacsPackagesFor;
    experimentalFetchTree = true;
    toInit = _lib: _attrs: "";
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
    ];
  };
in
doomPackages.emacsWithDoom.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit updateIntermediates updateScript;
  };
})
