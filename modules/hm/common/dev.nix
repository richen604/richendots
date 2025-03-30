{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.modules.common.dev;
in
{
  options.modules.common.dev = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development environment";
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
