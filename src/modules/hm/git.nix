{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:

let
  cfg = config.modules.git;

  git-picker =
    # TODO: this will eventually be a part of my git-timeshift project
    pkgs.writeShellScriptBin "git-commit-date" ''
      # Get date input
      read -p "Enter date (YYYY-MM-DD, MM-DD, or relative like '2 days ago'): " date_input
      if [ -z "$date_input" ]; then
        echo "No date entered, aborting"
        exit 1
      fi

      # If input is in MM-DD format, prepend current year
      if [[ $date_input =~ ^[0-1][0-9]-[0-3][0-9]$ ]]; then
        current_year=$(date +%Y)
        date_input="$current_year-$date_input"
      fi

      # Convert input to YYYY-MM-DD format
      formatted_date=$(date -d "$date_input" +%Y-%m-%d)
      if [ $? -ne 0 ]; then
        echo "Invalid date format"
        exit 1
      fi

      # Get time input
      read -p "Enter time (HH:MM): " time_input
      if [ -z "$time_input" ]; then
        echo "No time entered, aborting"
        exit 1
      fi

      # Validate time format
      if ! [[ $time_input =~ ^([0-1][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        echo "Invalid time format. Please use HH:MM (24-hour format)"
        exit 1
      fi

      # Format date for git (ISO 8601)
      commit_date="$formatted_date"T"$time_input:00"

      # Do the commit with the selected date
      GIT_COMMITTER_DATE="$commit_date" git commit --date="$commit_date" "$@"
    '';
in
{
  options.modules.git = {
    enable = lib.mkEnableOption "git module";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dialog
      git-picker
    ];

    programs.git = {
      enable = true;
      userName = userConfig.gitUser;
      userEmail = userConfig.gitEmail;
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
