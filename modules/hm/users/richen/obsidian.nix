{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.obsidian;

  obsidianDcol = pkgs.fetchurl {
    url = "https://github.com/HyDE-Project/obsidian/raw/refs/heads/main/obsidian.dcol";
    sha256 = "sha256-yaGOGoCcPANjVT7yvtg01Odd1MFj1pkdXILTY9+PU7k=";
  };

  wallbashTheme = pkgs.fetchFromGitHub {
    owner = "HyDE-Project";
    repo = "obsidian";
    rev = "main";
    sha256 = "sha256-dqGWP2KsjUjb65gnulZ+fe6wGcfaudhT0cpTw2QcUEI=";
  };

  # Script to create and monitor hardlinks
  linkScript = pkgs.writeShellScript "obsidian-todo-linker" ''
    OBSIDIAN_DIR="${cfg.projectsDir}"
    DEV_DIR="${cfg.devDir}"

    # Create obsidian projects directory if it doesn't exist
    mkdir -p "$OBSIDIAN_DIR"

    # Variable to track last update time
    last_update=0
    update_interval=1  # Minimum seconds between updates

    # Function to create/update hardlinks
    update_links() {
      current_time=$(date +%s)
      time_diff=$((current_time - last_update))
      
      # Only update if enough time has passed since last update
      if [ $time_diff -ge $update_interval ]; then
        find "$DEV_DIR" -maxdepth 2 -name "TODO.md" | while read -r todo_file; do
          project_name=$(basename "$(dirname "$todo_file")")
          target_link="$OBSIDIAN_DIR/$project_name-todo.md"
          
          # Remove existing link if it exists
          rm -f "$target_link"
          # Create new hardlink
          ln "$todo_file" "$target_link"
        done
        last_update=$current_time
      fi
    }

    # Initial link creation
    update_links

    # Monitor both directories for changes
    ${pkgs.inotify-tools}/bin/inotifywait -m -r -e modify,create,delete,move "$DEV_DIR" "$OBSIDIAN_DIR" | while read -r directory events filename; do
      if [[ "$filename" == "TODO.md" ]] || [[ "$filename" == *-todo.md ]]; then
        update_links
      fi
    done
  '';
in
{
  options.modules.obsidian = {
    enable = lib.mkEnableOption "obsidian module";
    # TODO: add backup methods
    backupPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Full paths for Obsidian backup locations";
    };

    projectsDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/obsidian/home/projects";
      description = "Directory where Obsidian project files are stored";
    };

    devDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/dev";
      description = "Directory containing development projects";
    };

    linker = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to link Project TODO.md files to Obsidian";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
      inotify-tools
    ];

    home.sessionVariables = {
      OBSIDIAN_VAULT = "$HOME/obsidian/home";
    };

    home.file = {

      ".config/hyde/wallbash/Wall-Ways/obsidian.dcol" = {
        source = obsidianDcol;
        force = true;
        mutable = true;
      };

      "obsidian/home/.obsidian/themes/Wallbash" = {
        source = wallbashTheme;
        recursive = true;
        force = true;
        mutable = true;
      };

    };

    systemd.user.services.obsidian-todo-linker = lib.mkIf cfg.linker {
      Unit = {
        Description = "Link and monitor project TODO files to Obsidian";
      };

      Service = {
        Type = "simple";
        ExecStart = "${linkScript}";
        Restart = "always";
        RestartSec = "5";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
