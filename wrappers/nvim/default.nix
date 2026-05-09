{
  inputs,
  pkgs,
  ...
}:

# TODO: lets setup plugins declaratively
(inputs.mnw.lib.wrap pkgs {
  enable = true;
  appName = "astronvim";

  aliases = [
    "vi"
    "vim"
  ];

  extraBinPath = [
    pkgs.fzf
    pkgs.ripgrep
    pkgs.cargo
    pkgs.rustc
    pkgs.gcc
  ];

  desktopEntry = true;

  luaFiles = [
    (pkgs.writeText "init.lua" (pkgs.lib.readFile ./astronvim/init.lua))
  ];

  plugins.start = [
    pkgs.vimPlugins.lazy-nvim
  ];

  plugins.startAttrs = {
    # astrocore = pkgs.vimPlugins.astrocore;
    # astrolsp = pkgs.vimPlugins.astrolsp;
    # astroui = pkgs.vimPlugins.astroui;
    # astrotheme = pkgs.vimPlugins.astrotheme;

    # astronvim = pkgs.vimUtils.buildVimPlugin {
    #   pname = "astronvim";
    #   version = "5.3.15";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "AstroNvim";
    #     repo = "AstroNvim";
    #     rev = "v5.3.15";
    #     hash = "sha256-3sMBH1Dr4F7RHYXmXK3QREUcPnFBjxlxWhPSRW7lh/w=";
    #   };
    #   doCheck = false;
    # };
  };

  plugins.dev.astronvim-config = {
    pure = ./astronvim;
    impure = "/mnt/dev/richendots/wrappers/nvim/astronvim";
  };

  providers.nodeJs.enable = true;
  providers.python3.enable = true;
})
