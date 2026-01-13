{
  inputs,
  pkgs,
  ...
}:
let
  zshWrapper = pkgs.callPackage ./module.nix { inherit inputs; };
in
(zshWrapper.apply {
  pkgs = pkgs;
  shellAliases = {
    ll = "ls -la";
    la = "ls -A";
    l = "ls -CF";
    grep = "grep --color=auto";
    fgrep = "fgrep --color=auto";
    egrep = "egrep --color=auto";
    mkdir = "mkdir -p";
    cp = "cp -i";
    mv = "mv -i";
    rm = "rm -i";
    vim = "nvim";
  };
  interactiveShellInit = ''
    eval "$(${pkgs.lib.getExe' pkgs.direnv "direnv"} hook zsh)"
  '';
  promptInit = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    source ${toString ./.p10k.zsh}

    bindkey '\e[1;3C' forward-word   # Alt+Right
    bindkey '\e[1;3D' backward-word  # Alt+Left

    # makes shell slow, consider enabling only when needed
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

    # todo: ideally this would be per project but npx might require this
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
  histSize = 10000;
  enableCompletion = true;
  enableBashCompletion = true;
  enableGlobalCompInit = true;
  enableLsColors = true;
  loginShellInit = ''
    # Powerlevel10k instant prompt
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi
  '';
  sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "firefox";
    PAGER = "less";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
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
  ohMyZsh = {
    enable = true;
    plugins = [
      "git"
      "sudo"
      "vscode"
      "z"
      "fzf"
      "extract"
      "gitfast"
    ];
  };
  plugins = [
    {
      name = "zsh-nix-shell";
      src = pkgs.zsh-nix-shell;
    }
  ];
  autosuggestions.enable = true;
}).wrapper
