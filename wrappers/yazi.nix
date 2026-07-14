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

  keymap.mgr.prepend_keymap = [
    {
      on = "M";
      run = "plugin mount";
      desc = "Mount manager";
    }
    {
      on = "C";
      run = "plugin ouch";
      desc = "Compress with ouch";
    }
    {
      on = "<Enter>";
      run = "plugin smart-enter";
      desc = "Enter directory or open file";
    }
    {
      on = "f";
      run = "plugin smart-filter";
      desc = "Smart filter";
    }
    {
      on = "p";
      run = "plugin smart-paste";
      desc = "Paste into hovered directory";
    }
    {
      on = "+";
      run = "plugin zoom 1";
      desc = "Zoom preview in";
    }
    {
      on = "-";
      run = "plugin zoom -1";
      desc = "Zoom preview out";
    }
  ];

  theme = {
    app.overall = {
      bg = "#0E120F";
    };
    mgr = {
      cwd = {
        fg = "#9AE6AD";
        bold = true;
      };
      border_symbol = "│";
      border_style = {
        fg = "#295233";
      };
      find_keyword = {
        fg = "#AAF0DC";
        bold = true;
      };
      find_position = {
        fg = "#578F65";
      };
      marker_copied = {
        fg = "#9AE6DA";
        bg = "#142825";
      };
      marker_cut = {
        fg = "#CCFFF7";
        bg = "#142825";
      };
      marker_marked = {
        fg = "#9AE6AD";
        bg = "#142825";
      };
      marker_selected = {
        fg = "#FFFFFF";
        bg = "#295233";
      };
    };
    tabs = {
      active = {
        fg = "#FFFFFF";
        bg = "#142825";
        bold = true;
      };
      inactive = {
        fg = "#578F65";
        bg = "#0E120F";
      };
    };
    mode = {
      normal_main = {
        fg = "#0E120F";
        bg = "#9AE6AD";
        bold = true;
      };
      normal_alt = {
        fg = "#9AE6AD";
        bg = "#142825";
      };
      select_main = {
        fg = "#0E120F";
        bg = "#CCFFF7";
        bold = true;
      };
      select_alt = {
        fg = "#CCFFF7";
        bg = "#142825";
      };
      unset_main = {
        fg = "#0E120F";
        bg = "#578F65";
        bold = true;
      };
      unset_alt = {
        fg = "#578F65";
        bg = "#142825";
      };
    };
    status = {
      overall = {
        fg = "#FFFFFF";
        bg = "#0E120F";
      };
      progress_normal = {
        fg = "#9AE6AD";
        bg = "#142825";
      };
      progress_error = {
        fg = "#CCFFF9";
        bg = "#142825";
      };
    };
    filetype.rules = [
      {
        mime = "image/*";
        fg = "#9AE6AD";
      }
      {
        mime = "{audio,video}/*";
        fg = "#9AE6D0";
      }
      {
        mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
        fg = "#CCFFF7";
      }
      {
        url = "*/";
        fg = "#AAF0DC";
        bold = true;
      }
      {
        url = "*";
        fg = "#FFFFFF";
      }
    ];
    git = {
      modified = {
        fg = "#CCFFF7";
      };
      added = {
        fg = "#9AE6AD";
      };
      untracked = {
        fg = "#578F65";
      };
      deleted = {
        fg = "#CCFFF9";
        bold = true;
      };
      ignored = {
        fg = "#295233";
      };
    };
  };

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
        path = toml.generate "theme.toml" theme;
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
  name = "yazi-grove";
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
