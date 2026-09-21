{ pkgs, richenLib, ... }:

pkgs.callPackage ./waybar/_waybar.nix {
  inherit richenLib;
  mangoPackage = richenLib.wrappers.mango-fern;
  outputs = [
    "BNQ BenQ GW2780 ET85P0086404U"
    "Dell Inc. Dell S2716DG #ASMV9wwvvm3d"
    "Samsung Electric Company Odyssey G70D H1AK500000"
  ];
}
