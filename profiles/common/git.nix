{ richenLib, ... }:
{
  programs.git = {
    enable = true;
    package = richenLib.wrappers.git;
    lfs.enable = true;
  };
}
