{
  forEachSystem,
  pkgsFor,
}:
forEachSystem (
  system:
  let
    pkgs = pkgsFor system;
  in
  pkgs.mkShellNoCC {
    allowSubstitutes = false;
    packages = with pkgs; [
      deadnix
      git
      hyperfine
      nil
      nixfmt
      statix
    ];
  }
)
