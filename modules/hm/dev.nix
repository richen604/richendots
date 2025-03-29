{ pkgs, ... }:

{
  home.packages = with pkgs; [
    code-cursor
    nixfmt-rfc-style
    nil
    nix-direnv
    direnv
    nix-output-monitor
    nix-fast-build
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
