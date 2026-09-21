{
  pkgs,
  richenLib,
  ...
}:

let
  firmware = richenLib.wrappers.glove80;
in
pkgs.writeShellApplication {
  name = "glove80-flash";
  runtimeInputs = with pkgs; [
    coreutils
    jq
    udisks2
    util-linux
  ];
  text = ''
    firmware=${firmware}/glove80.uf2
    check_only=false
    flash_started=false
    right_flashed=false
    left_flashed=false
    run_succeeded=false
    phase=argument-parsing

    progress() {
      printf '\n==> %s\n' "$1"
    }

    usage() {
      printf 'usage: glove80-flash [--check]\n'
    }

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --check) check_only=true ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
      esac
      shift
    done

    require_environment() {
      [ -s "$firmware" ] || { printf 'firmware is missing or empty: %s\n' "$firmware" >&2; exit 1; }
      for command in cp findmnt jq lsblk sleep stat udisksctl; do
        command -v "$command" >/dev/null || { printf 'required command is unavailable: %s\n' "$command" >&2; exit 1; }
      done
      udisksctl status >/dev/null || { printf 'cannot access the udisks2 service\n' >&2; exit 1; }
    }

    label_volumes() {
      local label=$1
      lsblk --json --paths --output PATH,LABEL,FSTYPE,TYPE \
        | jq -r --arg label "$label" \
          '.. | objects | select(.label? == $label) | [.path, .fstype] | @tsv'
    }

    usb_product_present() {
      local expected=$1
      local product_file product
      for product_file in /sys/bus/usb/devices/*/product; do
        [ -r "$product_file" ] || continue
        IFS= read -r product < "$product_file"
        [ "$product" = "$expected" ] && return 0
      done
      return 1
    }

    inspect_label() {
      local label=$1
      local lines=()
      mapfile -t lines < <(label_volumes "$label")
      if [ "''${#lines[@]}" -gt 1 ]; then
        printf 'refusing duplicate %s volumes\n' "$label" >&2
        return 1
      fi
      if [ "''${#lines[@]}" -eq 1 ]; then
        IFS=$'\t' read -r device filesystem <<< "''${lines[0]}"
        if [ "$filesystem" != vfat ]; then
          printf 'refusing %s volume %s with unexpected filesystem %s\n' "$label" "$device" "$filesystem" >&2
          return 1
        fi
        printf '%s\t%s\n' "$device" "$filesystem"
      fi
    }

    wait_for_side() {
      local expected=$1
      local other=$2
      local result

      while true; do
        if [ -n "$(label_volumes "$other")" ]; then
          inspect_label "$other" >/dev/null || true
          printf 'wrong half connected: expected %s, found %s\n' "$expected" "$other" >&2
          return 1
        fi
        result=$(inspect_label "$expected") || return 1
        if [ -n "$result" ]; then
          printf '%s\n' "''${result%%$'\t'*}"
          return 0
        fi
        sleep 1
      done
    }

    check_side() {
      local side=$1
      local keys=$2
      local label=$3
      local other=$4
      local device

      printf '\n%s half:\n' "$side"
      printf '  1. Connect only the physical %s-hand half with one USB cable and turn it off.\n' "''${side,,}"
      printf '  2. Hold %s (physical positions C6R6 + C3R3).\n' "$keys"
      printf '  3. While holding both keys, turn the half on, then release them.\n'
      printf 'Waiting for %s; no keyboard input is needed...\n' "$label"
      device=$(wait_for_side "$label" "$other") || exit 1
      printf '%s is valid: %s (vfat)\n' "$label" "$device"
    }

    guided_check() {
      printf 'This is a continuous read-only check of both bootloader volumes.\n'
      printf 'It does not mount or write either half. Press Ctrl-C to cancel.\n'

      check_side Right 'I + PgDn' GLV80RHBOOT GLV80LHBOOT

      printf '\nTurn the right half off and move the USB cable to the left half.\n'
      printf 'Waiting for GLV80RHBOOT to disconnect...\n'
      while [ -n "$(label_volumes GLV80RHBOOT)" ]; do
        sleep 1
      done

      check_side Left 'Magic + E' GLV80LHBOOT GLV80RHBOOT

      printf '\nBoth bootloader volumes passed.\n'
      printf 'Turn the left half off, then turn both halves on normally.\n'
    }

    mounted_by_script=false
    mounted_device=
    cleanup_mount() {
      if $mounted_by_script && [ -n "$mounted_device" ] && lsblk "$mounted_device" >/dev/null 2>&1; then
        udisksctl unmount -b "$mounted_device" >/dev/null || true
      fi
      mounted_by_script=false
      mounted_device=
    }

    report_exit() {
      local exit_status=$?
      cleanup_mount
      if [ "$exit_status" -ne 0 ]; then
        printf '\nERROR: glove80-flash stopped during: %s\n' "$phase" >&2
        if $flash_started && $right_flashed && ! $left_flashed; then
          printf 'The right half was flashed, but the left half was not.\n' >&2
          printf 'Keep the halves off and rerun the command to flash both halves before resetting or pairing them.\n' >&2
        elif $flash_started && ! $right_flashed; then
          printf 'No half was confirmed as flashed. It is safe to retry the command.\n' >&2
        fi
      elif $flash_started && ! $run_succeeded; then
        printf '\nThe flashing workflow ended before both halves completed.\n' >&2
      fi
    }

    trap report_exit EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    flash_side() {
      local side=$1
      local label=$2
      local other=$3
      local keys normal_product device mountpoint present retries

      case "$side" in
        Right)
          keys='I + PgDn'
          normal_product='Glove80 Right'
          ;;
        Left)
          keys='Magic + E'
          normal_product='Glove80 Left'
          ;;
      esac

      progress "$side half: enter bootloader mode"
      printf 'Turn it off. Hold %s (C6R6 + C3R3), turn it on, then release the keys.\n' "$keys"
      read -r -p "Press Enter when the $side half is in bootloader mode... " _
      printf 'Waiting for %s...\n' "$label"
      phase="waiting for $side bootloader volume $label"
      device=$(wait_for_side "$label" "$other") || exit 1
      printf 'Detected %s on %s with a vfat filesystem.\n' "$label" "$device"

      phase="locating the $side bootloader mount"
      mountpoint=$(findmnt -rn -S "$device" -o TARGET || true)
      if [ -z "$mountpoint" ]; then
        printf '%s is not mounted; mounting it through udisksctl...\n' "$label"
        read -r -p "Press Enter to mount the $side bootloader volume... " _
        phase="mounting $label through udisksctl"
        if ! udisksctl mount -b "$device"; then
          printf 'udisksctl could not mount %s on %s\n' "$label" "$device" >&2
          return 1
        fi
        mounted_by_script=true
        mounted_device=$device
        mountpoint=$(findmnt -rn -S "$device" -o TARGET || true)
      else
        printf '%s is already mounted.\n' "$label"
      fi
      if [ -z "$mountpoint" ] || [ ! -d "$mountpoint" ]; then
        printf 'could not locate mount for %s after mounting\n' "$device" >&2
        return 1
      fi
      printf 'Mountpoint: %s\n' "$mountpoint"

      phase="copying firmware to the $side half"
      printf 'Do not touch the power switch, cable, KVM, or USB switch during the copy.\n'
      read -r -p "Press Enter to copy firmware to the $side half... " _
      printf 'Copying %s to %s/flash.uf2...\n' "$firmware" "$mountpoint"
      if ! cp "$firmware" "$mountpoint/flash.uf2"; then
        printf 'failed to copy firmware to the %s half\n' "$side" >&2
        return 1
      fi
      printf 'Firmware copy completed.\n'

      phase="waiting for the $side bootloader to reboot"
      printf 'Waiting up to 10 seconds for %s to disappear...\n' "$label"
      present=true
      retries=10
      while [ "$retries" -gt 0 ]; do
        if ! lsblk "$device" >/dev/null 2>&1; then
          present=false
          break
        fi
        sleep 1
        retries=$((retries - 1))
      done

      if $present; then
        cleanup_mount
        printf '%s did not disappear after copying; the %s half is not confirmed flashed\n' "$label" "$side" >&2
        return 1
      fi

      mounted_by_script=false
      mounted_device=
      # a power-off also makes the volume disappear, so wait for normal usb mode.
      printf '%s disappeared. Waiting for %s to return in normal USB mode...\n' "$label" "$normal_product"
      phase="waiting for the $side half to return in normal USB mode"
      retries=30
      while [ "$retries" -gt 0 ]; do
        if usb_product_present "$normal_product"; then
          printf '%s returned in normal USB mode.\n' "$normal_product"
          read -r -p "Press Enter to confirm the $side half looks normal... " _
          return 0
        fi
        sleep 1
        retries=$((retries - 1))
      done

      printf '%s disappeared but %s did not return; this is not counted as success\n' "$label" "$normal_product" >&2
      printf 'Keep both halves off and retry the complete workflow.\n' >&2
      return 1
    }

    guided_factory_reset() {
      phase='manual factory reset and re-pairing'
      progress 'Manual factory reset: LEFT first, then RIGHT'
      printf 'This erases all BLE profiles. The script does not time or verify these physical actions.\n\n'
      printf 'LEFT HALF FIRST:\n'
      printf '  1. Turn both halves off.\n'
      printf '  2. Hold Magic + 3 (C6R6 + C3R2) on the left half.\n'
      printf '  3. Turn the left half on while holding both keys.\n'
      printf '  4. Keep holding for five seconds, then turn the left half off.\n\n'
      read -r -p 'Press Enter after the left reset is complete and the left half is off... ' _
      printf 'RIGHT HALF SECOND:\n'
      printf '  1. Keep both halves off.\n'
      printf '  2. Hold PgDn + 8 (C6R6 + C3R2) on the right half.\n'
      printf '  3. Turn the right half on while holding both keys.\n'
      printf '  4. Keep holding for five seconds, then turn the right half off.\n\n'
      read -r -p 'Press Enter after the right reset is complete and the right half is off... ' _
      printf 'RESTORE AND RE-PAIR:\n'
      printf '  1. Turn both halves on together; they will re-pair automatically.\n'
      printf '  2. Turn RGB on and confirm both halves illuminate, then turn RGB off.\n'
      printf '  3. Once the keyboard types again, press Enter here.\n'
      read -r -p 'Waiting for both halves to recover... ' _
      printf 'Wait at least one minute for the new settings to persist.\n'
      read -r -p 'After one minute, press Enter to finish... ' _
    }

    phase=preflight
    progress 'Preflight checks'
    require_environment
    printf 'Firmware: %s\n' "$firmware"
    printf 'Firmware size: %s bytes\n' "$(stat -c %s "$firmware")"
    printf 'udisks2 access and required commands are available.\n'
    if $check_only; then
      phase='guided bootloader check'
      guided_check
      run_succeeded=true
      exit 0
    fi

    printf 'This flashes both halves using the official power-on recovery sequence.\n'
    printf 'Use one USB cable and connect only the half being flashed.\n'
    printf 'Both halves will be factory-reset afterward, which erases all BLE profiles.\n'
    read -r -p 'Is a tested backup keyboard connected? [y/N] ' answer
    case "$answer" in y|Y|yes|YES) ;; *) printf 'cancelled\n'; exit 0 ;; esac
    read -r -p 'Turn both Glove80 halves off, then press Enter using the backup keyboard... ' _

    flash_started=true
    flash_side Right GLV80RHBOOT GLV80LHBOOT || exit 1
    right_flashed=true
    progress 'Right half complete; prepare the left half'
    printf 'Turn the right half off and move the USB cable to the left half.\n'
    read -r -p 'Press Enter after the cable is connected to the left half... ' _
    printf 'Waiting for GLV80RHBOOT to disconnect...\n'
    phase='waiting for the right bootloader volume to disconnect'
    while [ -n "$(label_volumes GLV80RHBOOT)" ]; do
      sleep 1
    done
    printf 'Right bootloader volume is disconnected.\n'

    flash_side Left GLV80LHBOOT GLV80RHBOOT || exit 1
    left_flashed=true
    progress 'Both firmware halves completed'

    guided_factory_reset
    phase=complete
    run_succeeded=true
    progress 'Glove80 workflow complete'
  '';
  meta.description = "Guided rootless Glove80 firmware flasher";
}
