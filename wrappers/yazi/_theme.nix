{ theme }:
{
  app.overall.bg = theme.bg.p;

  mgr = {
    cwd = {
      fg = theme.acc.p."6";
      bold = true;
    };
    border_symbol = "│";
    border_style.fg = theme.acc.p."2";
    find_keyword = {
      fg = theme.syntax.string;
      bold = true;
    };
    find_position.fg = theme.aliases.muted;
    marker_copied = {
      fg = theme.syntax.string;
      bg = theme.bg.s;
    };
    marker_cut = {
      fg = theme.ui.error;
      bg = theme.bg.s;
    };
    marker_marked = {
      fg = theme.acc.p."6";
      bg = theme.bg.s;
    };
    marker_selected = {
      fg = theme.txt.p;
      bg = theme.bg.s;
    };
  };

  tabs = {
    active = {
      fg = theme.txt.p;
      bg = theme.bg.s;
      bold = true;
    };
    inactive = {
      fg = theme.aliases.muted;
      bg = theme.bg.p;
    };
  };

  mode = {
    normal_main = {
      fg = theme.bg.p;
      bg = theme.acc.p."6";
      bold = true;
    };
    normal_alt = {
      fg = theme.acc.p."6";
      bg = theme.bg.s;
    };
    select_main = {
      fg = theme.bg.p;
      bg = theme.ui.warning;
      bold = true;
    };
    select_alt = {
      fg = theme.ui.warning;
      bg = theme.bg.s;
    };
    unset_main = {
      fg = theme.bg.p;
      bg = theme.aliases.muted;
      bold = true;
    };
    unset_alt = {
      fg = theme.aliases.muted;
      bg = theme.bg.s;
    };
  };

  status = {
    overall = {
      fg = theme.txt.p;
      bg = theme.bg.p;
    };
    progress_normal = {
      fg = theme.acc.p."6";
      bg = theme.bg.s;
    };
    progress_error = {
      fg = theme.ui.error;
      bg = theme.bg.s;
    };
  };

  filetype.rules = [
    {
      mime = "image/*";
      fg = theme.acc.p."6";
    }
    {
      mime = "{audio,video}/*";
      fg = theme.syntax.function;
    }
    {
      mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
      fg = theme.ui.warning;
    }
    {
      url = "*/";
      fg = theme.syntax.string;
      bold = true;
    }
    {
      url = "*";
      fg = theme.txt.p;
    }
  ];

  git = {
    modified.fg = theme.diff.modified;
    added.fg = theme.diff.added;
    untracked.fg = theme.aliases.muted;
    deleted = {
      fg = theme.diff.removed;
      bold = true;
    };
    ignored.fg = theme.acc.p."2";
  };
}
