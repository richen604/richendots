{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "glove80-flash-fern";
  runtimeInputs = with pkgs; [
    coreutils
    openssh
  ];
  text = builtins.readFile ./glove80-flash-fern.sh;
  meta.description = "Build and flash Glove80 firmware on Fern from Cedar";
}
