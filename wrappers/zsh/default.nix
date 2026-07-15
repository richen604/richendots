{
  pkgs,
  richenLib,
  ...
}:
let
  shellAliases = {
    grep = "rg";
    mkdir = "mkdir -pv";
    cp = "cp -i";
    mv = "mv -i";
    rm = "rm -i";
    vim = "nvim";
    v = "nvim";
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    ls = "eza --color=auto";
    ll = "eza -lh --color=auto --group-directories-first";
    la = "eza -la --color=auto --group-directories-first";
    lt = "eza -lh --color=auto --tree";
    cat = "bat --color=always -pp";
    less = "less -R";
    tree = "tree -C";
    gst = "git status -sb";
    gl = "git log --oneline --graph --decorate";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gco = "git checkout";
    gcb = "git checkout -b";
    gbr = "git branch -a";
    dr = "direnv reload";
    h = "htop";
    df = "df -h";
    du = "du -h --max-depth=1";
    free = "free -h";
    nix = "nix --quiet";
  };

  sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "glide";
    PAGER = "less";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    NIXPKGS_ALLOW_UNFREE = "1";
    DIRENV_CONFIG = toString (
      pkgs.linkFarm "direnv" [
        {
          name = "direnvrc";
          path = "${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
        }
        {
          name = "direnv.toml";
          path = pkgs.writeText "direnv.toml" ''
            # silent mode
            [global]
            log_format="-"
            log_filter="^$"
          '';
        }
      ]
    );
  };

  interactiveShellInit = ''
    ${pkgs.pokemon-colorscripts}/bin/pokemon-colorscripts -r 1,2 --no-title

    # Powerlevel10k instant prompt
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi

    eval "$(${pkgs.lib.getExe' pkgs.direnv "direnv"} hook zsh)"
  '';

  promptInit = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    source ${./.p10k.zsh}

    bindkey '\e[1;3C' forward-word   # Alt+Right
    bindkey '\e[1;3D' backward-word  # Alt+Left
  '';

  configDir = pkgs.linkFarm "zsh-config" [
    {
      name = ".zshenv";
      path = pkgs.writeText ".zshenv" ''
        HELPDIR="${pkgs.zsh}/share/zsh/$ZSH_VERSION/help"

        # Tell zsh how to find installed completions.
        for p in ''${(z)NIX_PROFILES}; do
            fpath=($p/share/zsh/site-functions $p/share/zsh/$ZSH_VERSION/functions $p/share/zsh/vendor-completions $fpath)
        done

        ${pkgs.lib.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (name: value: ''export ${name}="${toString value}"'') sessionVariables
        )}
      '';
    }
    {
      name = ".zprofile";
      path = pkgs.writeText ".zprofile" "";
    }
    {
      name = ".zshrc";
      path = pkgs.writeText ".zshrc" ''
        SAVEHIST=10000
        HISTSIZE=10000
        setopt HIST_IGNORE_DUPS
        setopt SHARE_HISTORY
        setopt HIST_FCNTL_LOCK

        # configure sane keyboard defaults
        . ${./zinputrc}

        bindkey -e

        autoload -Uz compinit
        compinit

        autoload -U +X bashcompinit && bashcompinit

        # Enable colors for ls and other commands
        if [[ -f ${pkgs.coreutils}/bin/dircolors ]]; then
          eval "$(${pkgs.coreutils}/bin/dircolors -b)"
          alias ls='ls --color=auto'
        fi
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

        ${interactiveShellInit}

        export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
        plugins=(sudo z fzf gitfast)
        source "$ZSH/oh-my-zsh.sh"

        # Load zsh-nix-shell
        if [[ -f "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/zsh-nix-shell.zsh" ]]; then
          source "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/zsh-nix-shell.zsh"
        fi

        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        export ZSH_AUTOSUGGEST_STRATEGY=(history)

        ${pkgs.lib.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (k: v: "alias -- ${k}=${pkgs.lib.escapeShellArg v}") shellAliases
        )}

        ${promptInit}

        # Disable some features to support TRAMP.
        if [ "$TERM" = dumb ]; then
            unsetopt zle prompt_cr prompt_subst
            unset RPS1 RPROMPT
            PS1='$ '
            PROMPT='$ '
        fi
      '';
    }
  ];
in
richenLib.lib.wrapPackage {
  package = pkgs.zsh;
  env = {
    SHELL = "${pkgs.zsh}/bin/zsh";
    ZDOTDIR = "${configDir}/";
  };
  passthru.configDir = configDir;
}
