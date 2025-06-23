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
    home.packages = with pkgs.userPkgs; [
      code-cursor
      nixfmt-rfc-style
      nil
      nix-output-monitor
      nix-fast-build

      # Node.js ecosystem
      pnpm
      npm-check-updates
      node2nix
      nodePackages.npm
      nodePackages.typescript
      nodePackages.ts-node
      nodePackages.nodemon

      # Node version management
      fnm
    ];

    programs = {
      direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
      };

      zsh = {
        initContent = pkgs.lib.mkAfter ''
          source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

          # fnm (Fast Node Manager) setup
          eval "$(fnm env --use-on-cd)"

          # pnpm setup
          export PNPM_HOME="$HOME/.local/share/pnpm"
          case ":$PATH:" in
            *":$PNPM_HOME:"*) ;;
            *) export PATH="$PNPM_HOME:$PATH" ;;
          esac

          # npm global packages path
          export NPM_CONFIG_PREFIX="$HOME/.npm-global"
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
        '';
      };
    };
  };
}
