{
  pkgs,
  richenLib,
  ...
}:
let
  vscodeTheme = import ./_theme.nix { inherit (richenLib) theme; };
  themeFile = pkgs.replaceVars ./grove-color-theme.json (
    vscodeTheme.replacements // { inherit (vscodeTheme) label; }
  );
  settingsFile = pkgs.replaceVars ./settings.json { inherit (vscodeTheme) label; };
  argvFile = pkgs.writeText "vscode-argv.json" (
    builtins.toJSON {
      "password-store" = "gnome-libsecret";
    }
  );
  publisher = "richendots";
  version = "1.0.0";
  packageJson = pkgs.writeText "package.json" (
    builtins.toJSON {
      name = vscodeTheme.extensionName;
      displayName = vscodeTheme.label;
      description = "Generated VS Code theme for ${richenLib.theme.name}";
      inherit publisher version;
      engines.vscode = "^1.80.0";
      categories = [ "Themes" ];
      contributes.themes = [
        {
          label = vscodeTheme.label;
          uiTheme = "vs-dark";
          path = "./themes/color-theme.json";
        }
      ];
    }
  );
  themeSource =
    pkgs.runCommand "${vscodeTheme.extensionName}-source" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        mkdir -p "$out/extension/themes"
        cp ${packageJson} "$out/extension/package.json"
        cp ${themeFile} "$out/extension/themes/color-theme.json"
        jq -e . "$out/extension/package.json" >/dev/null
        jq -e '
          .semanticHighlighting == true and
          (.colors | type == "object" and length > 100) and
          (.tokenColors | type == "array" and length > 20) and
          (.semanticTokenColors | type == "object" and length > 10)
        ' "$out/extension/themes/color-theme.json" >/dev/null
        theme_path="$(jq -r '.contributes.themes[0].path' "$out/extension/package.json")"
        test -f "$out/extension/''${theme_path#./}"
        jq -e --arg label ${pkgs.lib.escapeShellArg vscodeTheme.label} '.name == $label' \
          "$out/extension/themes/color-theme.json" >/dev/null
        if grep -q '@[A-Za-z]' "$out/extension/themes/color-theme.json"; then
          echo "unresolved VS Code theme replacement" >&2
          exit 1
        fi
        test "$(jq -r '.contributes.themes[0].label' "$out/extension/package.json")" = ${pkgs.lib.escapeShellArg vscodeTheme.label}
      '';
  groveThemeExtension =
    pkgs.runCommand "vscode-extension-${vscodeTheme.extensionName}-${version}"
      {
        pname = "vscode-extension-${vscodeTheme.extensionName}";
        inherit version;
        passthru = {
          vscodeExtName = vscodeTheme.extensionName;
          vscodeExtPublisher = publisher;
          vscodeExtUniqueId = "${publisher}.${vscodeTheme.extensionName}";
        };
      }
      ''
        extensionDir="$out/share/vscode/extensions/${publisher}.${vscodeTheme.extensionName}"
        mkdir -p "$extensionDir"
        cp -r ${themeSource}/extension/. "$extensionDir/"
      '';
in
{
  programs.vscode = {
    enable = true;
    extensions =
      with pkgs.vscode-extensions;
      [
        aaron-bond.better-comments
        bierner.markdown-preview-github-styles
        davidanson.vscode-markdownlint
        dbaeumer.vscode-eslint
        ecmel.vscode-html-css
        esbenp.prettier-vscode
        geequlim.godot-tools
        gruntfuggly.todo-tree
        ibm.output-colorizer
        jnoortheen.nix-ide
        mads-hartmann.bash-ide-vscode
        mkhl.shfmt
        ms-python.python
        ms-vscode-remote.remote-ssh
        redhat.vscode-yaml
        streetsidesoftware.code-spell-checker
        tamasfe.even-better-toml
        timonwong.shellcheck
        yoavbls.pretty-ts-errors
        yzhang.markdown-all-in-one
        ziglang.vscode-zig
      ]
      ++ [ groveThemeExtension ];
  };

  hjem.users.${richenLib.vars.username}.files = {
    ".config/Code/User/settings.json" = {
      type = "copy";
      permissions = "0644";
      source = settingsFile;
    };

    ".vscode/argv.json" = {
      type = "copy";
      permissions = "0644";
      source = argvFile;
    };
  };
}
