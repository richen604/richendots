{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  zshWrapper = pkgs.callPackage ./zsh/module.nix { inherit inputs; };
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
  };
  promptInit = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    source ${toString ./zsh/.p10k.zsh}
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
  plugins= [
    {
      name = "zsh-nix-shell";
      src = pkgs.zsh-nix-shell;
    }
  ];
  autosuggestions.enable = true;
}).wrapper
