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
      vscode = {
        enable = true;
        mutableExtensionsDir = true;
        profiles = {
          "default" = {
            extensions = with pkgs.vscode-extensions; [
              supermaven.supermaven
              github.vscode-pull-request-github
              github.vscode-github-actions
              github.vscode-pull-request-github
              esbenp.prettier-vscode
              yoavbls.pretty-ts-errors
              dbaeumer.vscode-eslint
              ms-vscode-remote.remote-ssh
              redhat.vscode-yaml
              davidanson.vscode-markdownlint
              timonwong.shellcheck
              yzhang.markdown-all-in-one
              gruntfuggly.todo-tree
              donjayamanne.githistory
              eamodio.gitlens
              aaron-bond.better-comments
              bierner.markdown-mermaid
              enkia.tokyo-night
              catppuccin.catppuccin-vsc-icons
              firefox-devtools.vscode-firefox-debug
              bierner.markdown-preview-github-styles
              jnoortheen.nix-ide
              alefragnani.project-manager
              leonardssh.vscord
            ];
          };
        };
      };
    };
    home.file.".config/Code/User/settings.json" = lib.mkForce {
      mutable = true;
      force = true;
      text = ''
        {
          "workbench.colorTheme": "Tokyo Night",
          "window.menuBarVisibility": "toggle",
          "editor.fontSize": 15,
          "editor.scrollbar.vertical": "hidden",
          "editor.scrollbar.verticalScrollbarSize": 0,
          "security.workspace.trust.untrustedFiles": "newWindow",
          "security.workspace.trust.startupPrompt": "never",
          "security.workspace.trust.enabled": false,
          "editor.minimap.side": "left",
          "editor.fontFamily": "'CaskaydiaCove Nerd Font Mono', 'monospace', monospace",
          "extensions.autoUpdate": false,
          "workbench.statusBar.visible": false,
          "terminal.external.linuxExec": "kitty",
          "terminal.explorerKind": "both",
          "terminal.sourceControlRepositoriesKind": "both",
          "telemetry.telemetryLevel": "off",
          "workbench.activityBar.location": "top",
          "window.customTitleBarVisibility": "auto",
          "workbench.iconTheme": "catppuccin-mocha",
          "editor.cursorSmoothCaretAnimation": "on",
          "editor.autoIndent": "full",
          "editor.formatOnSave": true,

          "nix.enableLanguageServer": true,
          "nix.formatterPath": "nixfmt",
          "nix.serverPath": "nil",
          "nix.hiddenLanguageServerErrors": [
            "textDocument/definition",
            "textDocument/formatting",
            "textDocument/documentSymbol"
          ],
          "nix.serverSettings": {
            "nil": {
              "formatting": {
                "command": [ "nixfmt" ]
              }
            }
          },
          "markdownlint.config": {
            "MD033": {
              "allowed_elements": [
                "nobr",
                "sup",
                "a",
                "div",
                "img",
                "br",
                "video",
                "kbd",
                "sub",
                "section",
                "details",
                "summary",
              ]
            }
          },
          "workbench.sideBar.location": "right",
        }
      '';
    };
  };
}
