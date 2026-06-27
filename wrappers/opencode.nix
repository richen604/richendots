{ pkgs, ... }:

pkgs.symlinkJoin {
  name = "opencode";
  paths = [ pkgs.opencode ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/opencode \
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
  '';
}
