{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }:
  # todo: zsh wrapper: completions do not work without nixos option environment.pathsToLink = [ "/share/zsh" ];
  {
    _class = "wrapper";

    options = {
      shellAliases = lib.mkOption {
        type = lib.types.attrsOf (lib.types.nullOr (lib.types.either lib.types.str lib.types.path));
        default = { };
        description = "Set of aliases for zsh shell.";
      };

      shellInit = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Shell script code called during zsh shell initialisation.";
      };

      histSize = lib.mkOption {
        type = lib.types.int;
        default = 2000;
        description = "Number of history lines to keep.";
      };

      histFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Location of the history file, this will default to ~/.zsh_history if not set.";
      };

      setOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "HIST_IGNORE_DUPS"
          "SHARE_HISTORY"
          "HIST_FCNTL_LOCK"
        ];
        description = "Configure zsh options.";
      };

      promptInit = lib.mkOption {
        type = lib.types.lines;
        default = ''
          # Note that to manually override this in ~/.zshrc you should run `prompt off`
          # before setting your PS1 and etc. Otherwise this will likely to interact with
          # your ~/.zshrc configuration in unexpected ways as the default prompt sets
          # a lot of different prompt variables.
          autoload -U promptinit && promptinit && prompt suse && setopt prompt_sp
        '';
        description = "Shell script code used to initialise the shell prompt.";
      };

      loginShellInit = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Shell script code called during login shell initialisation.";
      };

      interactiveShellInit = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Shell script code called during interactive shell initialisation.";
      };

      enableCompletion = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable zsh completion for all interactive zsh shells.";
      };

      enableBashCompletion = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable bash completion for all interactive zsh shells.";
      };

      enableGlobalCompInit = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable execution of compinit call for all interactive zsh shells.";
      };

      enableLsColors = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable extra colors in directory listings.";
      };

      ohMyZsh = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable Oh My Zsh.";
            };

            package = lib.mkOption {
              type = lib.types.package;
              default = config.pkgs.oh-my-zsh;
              defaultText = lib.literalExpression "pkgs.oh-my-zsh";
              description = "Package to install for Oh My Zsh.";
            };

            plugins = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "git" ];
              description = "List of Oh My Zsh plugins to enable.";
            };

            theme = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Name of the theme to use for Oh My Zsh. Empty string means no theme (use default zsh prompt).";
            };

            custom = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Path to a custom Oh My Zsh configuration directory.";
            };

            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Extra configuration lines to add to Oh My Zsh setup.";
            };
          };
        };
        default = { };
        description = "Options to configure Oh My Zsh.";
      };

      autosuggestions = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable zsh-autosuggestions.";
            };

            strategy = lib.mkOption {
              type = lib.types.listOf (
                lib.types.enum [
                  "history"
                  "completion"
                  "match_prev_cmd"
                ]
              );
              default = [ "history" ];
              description = "Set ZSH_AUTOSUGGEST_STRATEGY to choose the suggestion strategy.";
            };

            async = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable asynchronous mode for better performance.";
            };
          };
        };
        default = { };
        description = "Options to configure zsh-autosuggestions.";
      };

      syntaxHighlighting = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable zsh-syntax-highlighting.";
            };

            highlighters = lib.mkOption {
              type = lib.types.listOf (
                lib.types.enum [
                  "main"
                  "brackets"
                  "pattern"
                  "cursor"
                  "root"
                  "line"
                ]
              );
              default = [ "main" ];
              description = "Specifies the highlighters to be used by zsh-syntax-highlighting.";
            };

            styles = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Specifies custom styles to be highlighted by zsh-syntax-highlighting.";
              example = {
                "alias" = "fg=magenta,bold";
              };
            };

            patterns = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Specifies custom patterns to be highlighted by zsh-syntax-highlighting.";
              example = {
                "rm -rf *" = "fg=white,bold,bg=red";
              };
            };
          };
        };
        default = { };
        description = "Options to configure zsh-syntax-highlighting.";
      };

      sessionVariables = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
        default = { };
        description = "Environment variables that will be set for zsh sessions.";
        example = {
          EDITOR = "vim";
          BROWSER = "firefox";
          PATH = [
            "$PATH"
            "$HOME/.local/bin"
          ];
        };
      };

      shellGlobalAliases = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Set of global aliases for zsh shell. Global aliases are expanded anywhere on the command line.";
        example = {
          "..." = "../..";
          "L" = "| less";
          "G" = "| grep";
        };
      };

      plugins = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Name of the plugin.";
              };
              src = lib.mkOption {
                type = lib.types.path;
                description = "Path to the plugin source.";
              };
            };
          }
        );
        default = [ ];
        description = "List of zsh plugins to enable.";
        example = [
          {
            name = "zsh-autosuggestions";
            src = pkgs.zsh-autosuggestions;
          }
          {
            name = "zsh-syntax-highlighting";
            src = pkgs.zsh-syntax-highlighting;
          }
        ];
      };

      configDir = lib.mkOption {
        type = lib.types.str;
        default = toString (
          config.pkgs.linkFarm "zsh-config" [
            {
              name = ".zshenv";
              path = config.pkgs.writeText ".zshenv" ''
                # Only execute this file once per shell.
                if [ -n "''${__ETC_ZSHENV_SOURCED-}" ]; then return; fi
                __ETC_ZSHENV_SOURCED=1

                HELPDIR="${config.pkgs.zsh}/share/zsh/$ZSH_VERSION/help"

                # Tell zsh how to find installed completions.
                for p in ''${(z)NIX_PROFILES}; do
                    fpath=($p/share/zsh/site-functions $p/share/zsh/$ZSH_VERSION/functions $p/share/zsh/vendor-completions $fpath)
                done

                # Configure session variables.
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    name: value:
                    if lib.isList value then
                      ''export ${name}="${lib.concatStringsSep ":" value}"''
                    else
                      ''export ${name}="${value}"''
                  ) config.sessionVariables
                )}

                # Custom shell initialization.
                ${config.shellInit}

                # Read system-wide modifications.
                if test -f /etc/zprofile.local; then
                    . /etc/zprofile.local
                fi
              '';
            }
            {
              name = ".zprofile";
              path = config.pkgs.writeText ".zprofile" ''
                # Only execute this file once per shell.
                if [ -n "''${__ETC_ZPROFILE_SOURCED-}" ]; then return; fi
                __ETC_ZPROFILE_SOURCED=1

                # Login shell initialization.
                ${config.loginShellInit}

                # Read system-wide modifications.
                if test -f /etc/zprofile.local; then
                    . /etc/zprofile.local
                fi
              '';
            }
            {
              name = ".zshrc";
              path = config.pkgs.writeText ".zshrc" ''

                # Only execute this file once per shell.
                if [ -n "$__ETC_ZSHRC_SOURCED" -o -n "$NOSYSZSHRC" ]; then return; fi
                __ETC_ZSHRC_SOURCED=1

                # Configure history.
                SAVEHIST=${toString config.histSize}
                HISTSIZE=${toString config.histSize}
                ${lib.optionalString (config.histFile != null) ''
                  HISTFILE="${config.histFile}"
                ''}
                ${lib.concatStringsSep "\n" (map (option: "setopt ${option}") config.setOptions)}

                # configure sane keyboard defaults
                . ${./zinputrc}

                # Configure completion system.
                ${lib.optionalString config.enableCompletion ''
                  autoload -Uz compinit
                  ${lib.optionalString config.enableGlobalCompInit "compinit"}
                ''}

                ${lib.optionalString config.enableBashCompletion ''
                  # Enable bash completion compatibility
                  autoload -U +X bashcompinit && bashcompinit
                ''}

                # Configure colors.
                ${lib.optionalString config.enableLsColors ''
                  # Enable colors for ls and other commands
                  if [[ -f ${config.pkgs.coreutils}/bin/dircolors ]]; then
                    eval "$(${config.pkgs.coreutils}/bin/dircolors -b)"
                    alias ls='ls --color=auto'
                  fi
                  zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
                ''}

                # Interactive shell initialization.
                ${config.interactiveShellInit}

                # Configure Oh My Zsh.
                ${lib.optionalString config.ohMyZsh.enable ''
                  # Oh My Zsh configuration
                  export ZSH="${config.ohMyZsh.package}/share/oh-my-zsh"
                  ${lib.optionalString (config.ohMyZsh.custom != null) ''
                    export ZSH_CUSTOM="${config.ohMyZsh.custom}"
                  ''}

                  # Oh My Zsh theme
                  ${lib.optionalString (config.ohMyZsh.theme != "") ''
                    ZSH_THEME="${config.ohMyZsh.theme}"
                  ''}

                  # Oh My Zsh plugins
                  plugins=(${lib.concatStringsSep " " config.ohMyZsh.plugins})

                  # Extra Oh My Zsh configuration
                  ${config.ohMyZsh.extraConfig}

                  # Source Oh My Zsh
                  source "$ZSH/oh-my-zsh.sh"
                ''}

                # Load custom plugins.
                ${lib.concatStringsSep "\n" (
                  map (plugin: ''
                    # Load ${plugin.name}
                    if [[ -f "${plugin.src}/share/${plugin.name}/${plugin.name}.zsh" ]]; then
                      source "${plugin.src}/share/${plugin.name}/${plugin.name}.zsh"
                    elif [[ -f "${plugin.src}/share/zsh/${plugin.name}/${plugin.name}.zsh" ]]; then
                      source "${plugin.src}/share/zsh/${plugin.name}/${plugin.name}.zsh"
                    elif [[ -f "${plugin.src}/${plugin.name}.plugin.zsh" ]]; then
                      source "${plugin.src}/${plugin.name}.plugin.zsh"
                    fi
                  '') config.plugins
                )}

                # Configure zsh-autosuggestions.
                ${lib.optionalString config.autosuggestions.enable ''
                  # Load zsh-autosuggestions
                  source ${config.pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

                  # Configure autosuggestions strategy
                  export ZSH_AUTOSUGGEST_STRATEGY=(${lib.concatStringsSep " " config.autosuggestions.strategy})

                  # Configure async mode
                  ${lib.optionalString (!config.autosuggestions.async) ''
                    unset ZSH_AUTOSUGGEST_USE_ASYNC
                  ''}
                ''}

                # Configure zsh-syntax-highlighting.
                ${lib.optionalString config.syntaxHighlighting.enable ''
                  # Configure syntax highlighting highlighters
                  export ZSH_HIGHLIGHT_HIGHLIGHTERS=(${lib.concatStringsSep " " config.syntaxHighlighting.highlighters})

                  # Configure custom styles
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: style: "typeset -A ZSH_HIGHLIGHT_STYLES; ZSH_HIGHLIGHT_STYLES[${name}]='${style}'"
                    ) config.syntaxHighlighting.styles
                  )}

                  # Configure custom patterns
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      pattern: style: "typeset -A ZSH_HIGHLIGHT_PATTERNS; ZSH_HIGHLIGHT_PATTERNS['${pattern}']='${style}'"
                    ) config.syntaxHighlighting.patterns
                  )}

                  # Load zsh-syntax-highlighting (must be sourced at the end)
                  source ${config.pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
                ''}

                # Setup aliases.
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (k: v: "alias -- ${k}=${lib.escapeShellArg v}") (
                    lib.filterAttrs (k: v: v != null) config.shellAliases
                  )
                )}

                # Setup global aliases.
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (k: v: "alias -g -- ${k}=${lib.escapeShellArg v}") config.shellGlobalAliases
                )}

                # Initialize prompt.
                ${config.promptInit}

                # Disable some features to support TRAMP.
                if [ "$TERM" = dumb ]; then
                    unsetopt zle prompt_cr prompt_subst
                    unset RPS1 RPROMPT
                    PS1='$ '
                    PROMPT='$ '
                fi

                # Read system-wide modifications.
                if test -f /etc/zshrc.local; then
                    . /etc/zshrc.local
                fi
              '';
            }
          ]
        );
        description = "Directory to look for zsh config files.";
      };
    };

    config = {
      package = config.pkgs.zsh;
      promptInit = lib.mkIf config.ohMyZsh.enable (lib.mkDefault "");
      env = {
        SHELL = "${config.pkgs.zsh}/bin/zsh";
        ZDOTDIR = "${config.configDir}/";
      };
      passthru = {
        configDir = config.configDir;
      };
    };
  }
)
