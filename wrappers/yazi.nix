{
  pkgs,
  richenLib,
  ...
}:
let
  extraPackages = [
    pkgs.file
    pkgs.ffmpeg
    pkgs.ouch
    pkgs.p7zip
    pkgs.poppler-utils
    pkgs.wl-clipboard
  ];

  toml = pkgs.formats.toml { };

  settings = {
    mgr = {
      ratio = [
        1
        4
        3
      ];
      sort_by = "natural";
      sort_dir_first = true;
      linemode = "size";
      show_hidden = false;
      show_symlink = true;
      scrolloff = 8;
    };

    preview = {
      wrap = "yes";
      tab_size = 2;
      image_filter = "lanczos3";
      image_quality = 80;
    };

    opener = {
      edit = [
        {
          run = ''$EDITOR "$@"'';
          block = true;
          desc = "Edit";
          for = "unix";
        }
      ];
      open = [
        {
          run = ''xdg-open "$1"'';
          orphan = true;
          desc = "Open";
          for = "unix";
        }
      ];
      extract = [
        {
          run = ''ouch d -y "$@"'';
          block = true;
          desc = "Extract here";
          for = "unix";
        }
      ];
    };

    open.prepend_rules = [
      {
        mime = "text/*";
        use = "edit";
      }
      {
        mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
        use = [
          "extract"
          "open"
        ];
      }
    ];

    plugin = {
      prepend_previewers = [
        {
          mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
          run = "ouch --show-file-icons --archive-icon=''";
        }
      ];
      prepend_fetchers = [
        {
          url = "*";
          run = "git";
          group = "git";
        }
        {
          url = "*/";
          run = "git";
          group = "git";
        }
      ];
    };
  };

  leader = on: run: desc: {
    on = [ "<Space>" ] ++ on;
    inherit run desc;
  };

  keymap.mgr.prepend_keymap = [
    {
      on = "<Enter>";
      run = "plugin smart-enter";
      desc = "Enter directory or open file";
    }
  ]
  ++ [
    # Selection
    (leader [ "<Space>" ] [ "toggle" "arrow 1" ] "Toggle selection")

    # Files
    (leader [ "f" "a" ] "create" "Create file or directory")
    (leader [ "f" "A" ] "bulk_create" "Bulk create files")
    (leader [ "f" "r" ] "rename --cursor=before_ext" "Rename selected files")
    (leader [ "f" "d" ] "remove" "Trash selected files")
    (leader [ "f" "D" ] "remove --permanently" "Permanently delete selected files")
    (leader [ "f" "o" ] "open" "Open selected files")
    (leader [ "f" "O" ] "open --interactive" "Open with…")
    (leader [ "f" "y" ] "yank" "Yank selected files")
    (leader [ "f" "x" ] "yank --cut" "Cut selected files")
    (leader [ "f" "p" ] "plugin smart-paste" "Paste into hovered directory")
    (leader [ "f" "u" ] "unyank" "Cancel yank")
    (leader [ "f" "l" ] "link" "Create absolute symlink")
    (leader [ "f" "L" ] "link --relative" "Create relative symlink")
    (leader [ "f" "h" ] "hardlink" "Create hardlink")
    (leader [ "f" "c" ] "plugin ouch" "Compress with ouch")

    # Clipboard
    (leader [ "c" "y" ] "plugin wl-clipboard" "Copy files to system clipboard")
    (leader [ "c" "p" ] "copy path" "Copy file path")
    (leader [ "c" "u" ] "copy url" "Copy file URL")
    (leader [ "c" "d" ] "copy dirpath" "Copy directory path")
    (leader [ "c" "D" ] "copy dirurl" "Copy directory URL")
    (leader [ "c" "f" ] "copy filename" "Copy filename")
    (leader [ "c" "n" ] "copy name_without_ext" "Copy filename without extension")

    # Go
    (leader [ "g" "h" ] "cd ~" "Go home")
    (leader [ "g" "c" ] "cd ~/.config" "Go to config")
    (leader [ "g" "d" ] "cd ~/Downloads" "Go to downloads")
    (leader [ "g" "t" ] "plugin trash" "Go to trash")
    (leader [ "g" "g" ] "cd --interactive" "Jump interactively")
    (leader [ "g" "f" ] "follow" "Follow hovered symlink")

    # Search and sort
    (leader [ "s" "f" ] "plugin smart-filter" "Smart filter")
    (leader [ "s" "n" ] "search --via=fd" "Search filenames")
    (leader [ "s" "c" ] "search --via=rg" "Search file contents")
    (leader [ "s" "j" ] "plugin fzf" "Jump with fzf")
    (leader [ "s" "z" ] "plugin zoxide" "Jump with zoxide")
    (leader [ "s" "s" "n" ] "sort natural --reverse=no" "Sort naturally")
    (leader [ "s" "s" "N" ] "sort natural --reverse=yes" "Sort naturally, reverse")
    (leader [ "s" "s" "a" ] "sort alphabetical --reverse=no" "Sort alphabetically")
    (leader [ "s" "s" "A" ] "sort alphabetical --reverse=yes" "Sort alphabetically, reverse")
    (leader [ "s" "s" "m" ] [ "sort mtime --reverse=no" "linemode mtime" ] "Sort by modified time")
    (leader [ "s" "s" "M" ] [ "sort mtime --reverse=yes" "linemode mtime" ]
      "Sort by modified time, reverse"
    )
    (leader [ "s" "s" "b" ] [ "sort btime --reverse=no" "linemode btime" ] "Sort by birth time")
    (leader [ "s" "s" "B" ] [ "sort btime --reverse=yes" "linemode btime" ]
      "Sort by birth time, reverse"
    )
    (leader [ "s" "s" "e" ] "sort extension --reverse=no" "Sort by extension")
    (leader [ "s" "s" "E" ] "sort extension --reverse=yes" "Sort by extension, reverse")
    (leader [ "s" "s" "s" ] [ "sort size --reverse=no" "linemode size" ] "Sort by size")
    (leader [ "s" "s" "S" ] [ "sort size --reverse=yes" "linemode size" ] "Sort by size, reverse")
    (leader [ "s" "s" "r" ] "sort random --reverse=no" "Sort randomly")

    # Tabs and tasks
    (leader [ "t" "n" ] "tab_create --current" "Create tab in current directory")
    (leader [ "t" "r" ] "tab_rename --interactive" "Rename current tab")
    (leader [ "t" "h" ] "tab_switch -1 --relative" "Previous tab")
    (leader [ "t" "l" ] "tab_switch 1 --relative" "Next tab")
    (leader [ "t" "H" ] "tab_swap -1" "Move tab left")
    (leader [ "t" "L" ] "tab_swap 1" "Move tab right")
    (leader [ "t" "w" ] "tasks:show" "Show task manager")

    # View
    (leader [ "v" "h" ] "hidden toggle" "Toggle hidden files")
    (leader [ "v" "s" ] "spot" "Spot hovered file")
    (leader [ "v" "z" "i" ] "plugin zoom 1" "Zoom preview in")
    (leader [ "v" "z" "o" ] "plugin zoom -1" "Zoom preview out")
    (leader [ "v" "l" "s" ] "linemode size" "Show sizes")
    (leader [ "v" "l" "p" ] "linemode permissions" "Show permissions")
    (leader [ "v" "l" "b" ] "linemode btime" "Show birth time")
    (leader [ "v" "l" "m" ] "linemode mtime" "Show modified time")
    (leader [ "v" "l" "o" ] "linemode owner" "Show owners")
    (leader [ "v" "l" "n" ] "linemode none" "Hide line metadata")

    # Utilities and session
    (leader [ "u" "m" ] "plugin mount" "Mount manager")
    (leader [ "u" "s" ] "shell --interactive" "Run shell command")
    (leader [ "u" "S" ] "shell --block --interactive" "Run blocking shell command")
    (leader [ "q" "q" ] "quit" "Quit")
    (leader [ "q" "Q" ] "quit --no-cwd-file" "Quit without changing directory")
    (leader [ "q" "c" ] "close" "Close current tab")
    (leader [ "q" "s" ] "suspend" "Suspend Yazi")
    (leader [ "q" "h" ] "help" "Open full help")
  ];

  theme = import ./yazi/_theme.nix { inherit (richenLib) theme; };
  baseTheme = toml.generate "yazi-base-theme.toml" theme;
  iconThemeScript = pkgs.writeText "yazi-icon-theme.pl" ''
    use strict;
    use warnings;

    my $in_icons = 0;

    while (<>) {
      $in_icons = 1 if /^\[icon\]\s*$/;
      next unless $in_icons;

      s/fg = "#[0-9a-fA-F]{6}"/"fg = \"" . grove_color($&) . "\""/e;
      print;
    }

    sub grove_color {
      my ($entry) = @_;
      my ($hex) = $entry =~ /#([0-9a-fA-F]{6})/;
      my ($r, $g, $b) = map { hex($_) / 255 } $hex =~ /(..)(..)(..)/;
      my $max = $r > $g ? ($r > $b ? $r : $b) : ($g > $b ? $g : $b);
      my $min = $r < $g ? ($r < $b ? $r : $b) : ($g < $b ? $g : $b);
      my $delta = $max - $min;
      my $lightness = ($max + $min) / 2;
      my $saturation = $max == 0 ? 0 : $delta / $max;

      return "${richenLib.theme.txt.p}" if $saturation < 0.18 && $lightness > 0.65;
      return "${richenLib.theme.aliases.muted}" if $saturation < 0.18;

      my $hue = 0;
      if ($delta != 0) {
        if ($max == $r) {
          $hue = 60 * (($g - $b) / $delta);
          $hue += 360 if $hue < 0;
        } elsif ($max == $g) {
          $hue = 60 * (($b - $r) / $delta + 2);
        } else {
          $hue = 60 * (($r - $g) / $delta + 4);
        }
      }

      return "${richenLib.theme.ui.error}" if $hue < 15 || $hue >= 345;
      return "${richenLib.theme.syntax.function}" if $hue < 45;
      return "${richenLib.theme.ui.warning}" if $hue < 75;
      return "${richenLib.theme.acc.p."6"}" if $hue < 150;
      return "${richenLib.theme.syntax.string}" if $hue < 190;
      return "${richenLib.theme.syntax.type}" if $hue < 250;
      return "${richenLib.theme.syntax.constant}" if $hue < 290;
      return "${richenLib.theme.syntax.function}";
    }
  '';
  generatedTheme = pkgs.runCommandLocal "yazi-theme.toml" { nativeBuildInputs = [ pkgs.perl ]; } ''
    install -m 0644 ${baseTheme} $out
    printf '\n' >> $out
    perl ${iconThemeScript} ${pkgs.yazi-unwrapped.srcs.code_src}/yazi-config/preset/theme-dark.toml >> $out
  '';

  extraFiles = [
    {
      name = "init.lua";
      file.path = pkgs.writeText "yazi-init.lua" ''
        require("full-border"):setup {
          type = ui.Border.ROUNDED,
        }

        require("git"):setup {
          order = 1500,
        }
      '';
    }
    {
      name = "plugins/full-border.yazi";
      file.path = pkgs.yaziPlugins.full-border;
    }
    {
      name = "plugins/git.yazi";
      file.path = pkgs.yaziPlugins.git;
    }
    {
      name = "plugins/mount.yazi";
      file.path = pkgs.yaziPlugins.mount;
    }
    {
      name = "plugins/ouch.yazi";
      file.path = pkgs.yaziPlugins.ouch;
    }
    {
      name = "plugins/smart-enter.yazi";
      file.path = pkgs.yaziPlugins.smart-enter;
    }
    {
      name = "plugins/smart-filter.yazi";
      file.path = pkgs.yaziPlugins.smart-filter;
    }
    {
      name = "plugins/smart-paste.yazi";
      file.path = pkgs.yaziPlugins.smart-paste;
    }
    {
      name = "plugins/zoom.yazi";
      file.path = pkgs.yaziPlugins.zoom;
    }
    {
      name = "plugins/wl-clipboard.yazi";
      file.path = pkgs.yaziPlugins.wl-clipboard;
    }
  ];

  configDir = pkgs.linkFarm "yazi-merged-config" (
    [
      {
        name = "yazi.toml";
        path = toml.generate "yazi.toml" settings;
      }
      {
        name = "keymap.toml";
        path = toml.generate "keymap.toml" keymap;
      }
      {
        name = "theme.toml";
        path = generatedTheme;
      }
    ]
    ++ map (file: {
      inherit (file) name;
      path = file.file.path;
    }) extraFiles
  );

  yazi = richenLib.lib.wrapPackage {
    package = pkgs.yazi;
    runtimeInputs = extraPackages;
    env.YAZI_CONFIG_HOME = configDir;
    passthru.configDir = configDir;
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "yazi-kitty";
    desktopName = "Yazi";
    genericName = "File Manager";
    comment = "Terminal file manager";
    exec = "kitty --class yazi -e ${pkgs.lib.getExe yazi} %U";
    icon = "system-file-manager";
    terminal = false;
    categories = [
      "System"
      "FileManager"
      "FileTools"
    ];
    mimeTypes = [
      "inode/directory"
      "application/zip"
      "application/x-tar"
      "application/gzip"
      "application/x-bzip2"
      "application/x-7z-compressed"
      "application/x-rar-compressed"
      "application/zstd"
      "application/x-xz"
    ];
  };
in
pkgs.symlinkJoin {
  name = "yazi-${richenLib.theme.name}";
  paths = [
    yazi
    desktopItem
  ];
  postBuild = ''
    if [ -L $out/share ]; then
      rm $out/share
      mkdir -p $out/share
      for path in ${yazi}/share/*; do
        ln -s "$path" "$out/share/$(basename "$path")"
      done
    fi

    if [ -L $out/share/applications ]; then
      rm $out/share/applications
      mkdir -p $out/share/applications
      for path in ${yazi}/share/applications/*; do
        ln -s "$path" "$out/share/applications/$(basename "$path")"
      done
    fi

    ln -s ${desktopItem}/share/applications/yazi-kitty.desktop $out/share/applications/yazi-kitty.desktop
  '';
}
