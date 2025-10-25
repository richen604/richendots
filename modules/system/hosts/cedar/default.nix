{ pkgs, ... }:
{
  imports = [
    ../../common/nix.nix
  ];

  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    wpa_supplicant
    kitty
  ];

  services.code-server = {
    enable = true;
    package = pkgs.vscode-with-extensions.override {
      vscode = pkgs.code-server;
      vscodeExtensions = with pkgs.vscode-extensions; [
        aaron-bond.better-comments
        alefragnani.project-manager
        bierner.emojisense
        bierner.markdown-mermaid
        bierner.markdown-preview-github-styles
        catppuccin.catppuccin-vsc-icons
        davidanson.vscode-markdownlint
        dbaeumer.vscode-eslint
        donjayamanne.githistory
        eamodio.gitlens
        ecmel.vscode-html-css
        aaron-bond.better-comments
        enkia.tokyo-night
        esbenp.prettier-vscode
        firefox-devtools.vscode-firefox-debug
        geequlim.godot-tools
        github.copilot
        github.vscode-github-actions
        github.vscode-pull-request-github
        golang.go
        ibm.output-colorizer
        jnoortheen.nix-ide
        leonardssh.vscord
        mads-hartmann.bash-ide-vscode
        mkhl.shfmt
        ms-dotnettools.csdevkit
        ms-dotnettools.csharp
        ms-dotnettools.vscode-dotnet-runtime
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.cpptools-extension-pack
        ms-vscode.makefile-tools
        ms-vscode-remote.remote-ssh
        redhat.vscode-yaml
        saoudrizwan.claude-dev
        streetsidesoftware.code-spell-checker
        tamasfe.even-better-toml
        timonwong.shellcheck
        yoavbls.pretty-ts-errors
        yzhang.markdown-all-in-one
        ziglang.vscode-zig
      ];
    };
  };
}
