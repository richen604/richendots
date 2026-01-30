{ pkgs, ... }:

pkgs.writeScriptBin "gct" ''
  #!/usr/bin/env bash
  PATH=$PATH:${
    pkgs.lib.makeBinPath [
      pkgs.gum
      pkgs.coreutils
      pkgs.git
    ]
  }
  set -euo pipefail

  NOW_EPOCH=$(date +%s)

  # Get latest commit time (if repo has commits)
  if git rev-parse --git-dir > /dev/null 2>&1 && git rev-parse HEAD > /dev/null 2>&1; then
    LAST_COMMIT_EPOCH=$(git log -1 --format=%ct)
  else
    LAST_COMMIT_EPOCH=0
  fi

  # Use whichever is later
  BASE_EPOCH=$NOW_EPOCH
  if (( LAST_COMMIT_EPOCH > NOW_EPOCH )); then
    BASE_EPOCH=$LAST_COMMIT_EPOCH
  fi

  BASE_DATE=$(date -d "@$BASE_EPOCH" +%Y-%m-%d)

  BLOCKS=()

  # Generate future 30-min blocks starting from BASE_EPOCH
  for day_offset in 0 1; do
    DAY=$(date -d "$BASE_DATE +$day_offset day" +%Y-%m-%d)

    for h in $(seq 0 23); do
      for m in 0 30; do
        TS_STRING="$DAY $(printf "%02d:%02d:00" "$h" "$m")"
        CANDIDATE=$(date -d "$TS_STRING" +%s)

        if (( CANDIDATE > BASE_EPOCH )); then
          BLOCKS+=("$(date -d "$TS_STRING" +'%Y-%m-%d %H:%M')")
        fi
      done
    done
  done

  # If still empty (very rare edge), just allow next day full
  if [ ''${#BLOCKS[@]} -eq 0 ]; then
    DAY=$(date -d "$BASE_DATE +1 day" +%Y-%m-%d)
    for h in $(seq -w 0 23); do
      BLOCKS+=("$DAY $h:00" "$DAY $h:30")
    done
  fi

  BLOCK=$(printf "%s\n" "''${BLOCKS[@]}" | gum choose --header "Pick a time block")

  DAY_PART=''${BLOCK% *}
  TIME_PART=''${BLOCK#* }

  HOUR=''${TIME_PART%:*}
  BASE_MIN=''${TIME_PART#*:}

  if [[ "$BASE_MIN" == "00" ]]; then
    MINUTE=$(shuf -i 0-29 -n 1)
  else
    MINUTE=$(shuf -i 30-59 -n 1)
  fi

  SECOND=$(shuf -i 0-59 -n 1)

  MINUTE=$(printf "%02d" "$MINUTE")
  SECOND=$(printf "%02d" "$SECOND")

  FINAL="$DAY_PART $HOUR:$MINUTE:$SECOND"

  gum style --foreground 212 "Using commit time: $FINAL"

  GIT_AUTHOR_DATE="$FINAL" \
  GIT_COMMITTER_DATE="$FINAL" \
  git commit "$@"
''
