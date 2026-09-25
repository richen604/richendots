{ inputs, pkgs, ... }:

let
  upstream = inputs.opencode.packages.${pkgs.system}.opencode;
  opencode =
    (upstream.override {
      node_modules = upstream.node_modules.override {
        hash = "sha256-H9G54uuDIuPaQ3d9db/LmdtJ/OUDQodIkqdy6AHtPWo=";
      };
    }).overrideAttrs
      {
        # OpenCode 2 treats `completion` as a working directory, so upstream's
        # completion generation fails. Remove it until the pinned flake fixes it.
        postInstall = "";
      };
in

pkgs.symlinkJoin {
  name = "opencode";
  paths = [ opencode ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/opencode \
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
  '';
}
