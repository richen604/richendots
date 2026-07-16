{ pkgs }:

pkgs.writeShellApplication {
  name = "profile-eval";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.hyperfine
    pkgs.nix
  ];
  text = ''
        usage() {
          cat <<'EOF'
    Usage: profile-eval [OPTIONS] [HOST ...]

    Benchmark and profile exact NixOS host toplevel evals.

    Options:
      --flake PATH       Flake path or ref to evaluate (default: .)
      --out DIR          Directory for outputs (default: .diagnostics/eval)
      --benchmark-only   Run hyperfine and NIX_SHOW_STATS only
      --profile-only     Run eval profiler only
      -h, --help         Show this help

    Default hosts: cedar fern oak

    Examples:
      nix run .#profile-eval
      nix run .#profile-eval -- --profile-only cedar
      nix run .#profile-eval -- --out /tmp/richendots-eval fern oak
    EOF
        }

        flake="."
        out_dir=".diagnostics/eval"
        run_benchmark=1
        run_profile=1
        hosts=()

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --flake)
              flake="''${2:?--flake requires a value}"
              shift 2
              ;;
            --out)
              out_dir="''${2:?--out requires a value}"
              shift 2
              ;;
            --benchmark-only)
              run_benchmark=1
              run_profile=0
              shift
              ;;
            --profile-only)
              run_benchmark=0
              run_profile=1
              shift
              ;;
            -h|--help)
              usage
              exit 0
              ;;
            --)
              shift
              while [[ $# -gt 0 ]]; do
                hosts+=("$1")
                shift
              done
              ;;
            -*)
              printf 'unknown option: %s\n' "$1" >&2
              usage >&2
              exit 2
              ;;
            *)
              hosts+=("$1")
              shift
              ;;
          esac
        done

        if [[ ''${#hosts[@]} -eq 0 ]]; then
          hosts=(cedar fern oak)
        fi

        mkdir -p "$out_dir"

        eval_attr() {
          local host="$1"
          printf '%s#nixosConfigurations.%s.config.system.build.toplevel.drvPath' "$flake" "$host"
        }

    eval_once() {
      local host="$1"
      nix --quiet eval --raw "$(eval_attr "$host")" \
        --read-only \
        --no-write-lock-file \
        --option eval-cache false \
        --option allow-import-from-derivation false
    }

    summarize_profile() {
      local profile_file="$1"
      local summary_file="$2"
      local tokens=(
        "hosts/cedar/media.nix"
        "services/web-apps/immich.nix"
        "nixarr"
        "wrappers/doom-emacs/_no-ifd.nix"
        "wrappers/doom-emacs/default.nix"
        "profiles/gui"
        "profiles/desktop"
        "profiles/laptop"
        "wrappers/glide/default.nix"
        "wrappers/waybar.nix"
        "wrappers/waybar-laptop.nix"
        "wrappers/mango/_base-config.nix"
        "wrappers/mango/default.nix"
        "wrappers/mango/mango-laptop.nix"
        "profiles/desktop/sunshine.nix"
        "catppuccin-gtk"
        "python313"
        "formats.json"
        "writeShellApplication"
        "doom-emacs"
        "emacs"
        "overrideScope"
        "mapAttrs"
        "wrappers"
        "modules.nix"
        "derivationStrict"
      )

      : >"$summary_file"
      for token in "''${tokens[@]}"; do
        local total=0
        local line count
        while IFS= read -r line; do
          if [[ "$line" == *"$token"* ]]; then
            count="''${line##* }"
            if [[ "$count" =~ ^[0-9]+$ ]]; then
              total=$((total + count))
            fi
          fi
        done <"$profile_file"
        printf '%12d %s\n' "$total" "$token" >>"$summary_file"
      done
      sort -nr "$summary_file" -o "$summary_file"
      cat "$summary_file"
    }

        for host in "''${hosts[@]}"; do
          if [[ "$run_benchmark" -eq 1 ]]; then
            printf '== benchmark %s ==\n' "$host"
            hyperfine \
              --warmup 1 \
              --runs 3 \
              --export-markdown "$out_dir/$host-hyperfine.md" \
              "nix --quiet eval --raw '$(eval_attr "$host")' --read-only --no-write-lock-file --option eval-cache false --option allow-import-from-derivation false"

            printf '== stats %s ==\n' "$host"
            NIX_SHOW_STATS=1 eval_once "$host" >"$out_dir/$host-drv-path.txt" 2>"$out_dir/$host-stats.txt"
            cat "$out_dir/$host-stats.txt"
          fi

      if [[ "$run_profile" -eq 1 ]]; then
        printf '== profile %s ==\n' "$host"
        profile_file="$out_dir/$host-eval-profile.folded"
        nix --quiet eval --raw "$(eval_attr "$host")" \
          --read-only \
          --no-write-lock-file \
          --option eval-cache false \
          --option allow-import-from-derivation false \
          --option eval-profiler flamegraph \
          --option eval-profile-file "$profile_file" \
          >"$out_dir/$host-profile-drv-path.txt"
        summarize_profile "$profile_file" "$out_dir/$host-profile-summary.txt"
      fi
        done

        printf 'outputs: %s\n' "$out_dir"
  '';
}
