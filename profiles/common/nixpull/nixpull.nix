{
  config,
  pkgs,
  lib,
  ...
}:

let
  packages = import ./_packages.nix { inherit config pkgs lib; };
in
{
  imports = [ (import ./_services.nix packages) ];
  options.services.nixpull = import ./_options.nix { inherit lib; };
}
