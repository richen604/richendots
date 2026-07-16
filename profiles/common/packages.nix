{ pkgs, richenLib, ... }:
{
  environment.systemPackages = [
    pkgs.yubikey-personalization
    pkgs.yubikey-touch-detector
    pkgs.age
    pkgs.age-plugin-yubikey
    pkgs.pam_u2f
    richenLib.wrappers.zsh
    richenLib.wrappers.git
    pkgs.neovim
    richenLib.wrappers.doom-emacs
    richenLib.wrappers.yazi
    pkgs.tealdeer
    pkgs.bat
    pkgs.tree
    pkgs.htop
    pkgs.fastfetch
    pkgs.tmux
    pkgs.less
    pkgs.ripgrep
    pkgs.jq
    pkgs.fd
    pkgs.killall
    pkgs.fzf
    pkgs.trash-cli
    pkgs.gawk
    pkgs.bash-completion
    pkgs.unzip
    pkgs.lm_sensors
    pkgs.pciutils
    pkgs.direnv
  ];

  environment.pathsToLink = [ "/share/zsh" ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libgcc
      zlib
      openssl
      icu
    ];
  };
}
