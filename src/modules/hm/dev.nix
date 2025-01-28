{ pkgs, ... }:

{
  home.packages = with pkgs; [
    code-cursor
    nixfmt-rfc-style
    nix-direnv
    nil
    direnv
  ];

  programs = {
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      initExtra = pkgs.lib.mkAfter ''
        source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
      '';
    };
  };
}
