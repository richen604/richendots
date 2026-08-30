target=fern
remote_flake=/home/richen/newdev/richendots
check_only=false

usage() {
  printf 'usage: glove80-flash-fern [--check]\n'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) check_only=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

if [ "$(hostname -s)" != cedar ]; then
  printf 'refusing to run outside Cedar\n' >&2
  exit 1
fi

progress() {
  printf '\n==> %s\n' "$1"
}

remote() {
  ssh -A "$target" "$@"
}

progress 'Fern preflight'
[ "$(remote hostname -s)" = fern ] || {
  printf 'SSH target did not identify itself as Fern\n' >&2
  exit 1
}
remote "for command in bash cp findmnt lsblk nix sleep stat sudo; do command -v \"\$command\" >/dev/null || exit 1; done"
printf 'SSH target and required Fern commands are available.\n'

progress 'Build firmware on Fern'
build_output=$(remote nix build "$remote_flake#glove80" --no-link --print-out-paths)
printf '%s\n' "$build_output"
mapfile -t build_lines <<< "$build_output"
firmware_store=${build_lines[$((${#build_lines[@]} - 1))]}
firmware_store=${firmware_store//$'\r'/}
firmware=$firmware_store/glove80.uf2
remote test -s "$firmware"
printf 'Firmware: %s:%s\n' "$target" "$firmware"

if $check_only; then
  progress 'Read-only check complete'
  printf 'No volume was mounted and no firmware was copied.\n'
  exit 0
fi

printf '\nThis command only accepts Fern boot volumes GLV80RHBOOT and GLV80LHBOOT.\n'
printf 'Keep this Cedar terminal and its SSH agent available for the whole run.\n'
read -r -p 'Turn both Glove80 halves off, then press Enter... ' _

flash_side() {
  local side=$1
  local keys=$2
  local label=$3
  local other=$4
  local product=$5
  local mount_name=$6

  progress "$side half"
  printf 'Connect only the %s half to Fern. Hold %s, switch it on, then release.\n' "$side" "$keys"
  read -r -p "Press Enter when the $side bootloader light is flashing quickly... " _

  # A tty lets Fern's PAM configuration authenticate sudo using Cedar's
  # forwarded SSH agent. The remote script still validates the exact label,
  # filesystem, and uniqueness before mounting anything.
  ssh -A -tt "$target" bash -s -- "$firmware" "$side" "$label" "$other" "$product" "$mount_name" <<'REMOTE'
set -euo pipefail
firmware=$1
side=$2
label=$3
other=$4
product=$5
mount_name=$6

volumes() {
  local wanted=$1
  lsblk -nrpo NAME,LABEL,FSTYPE,TYPE | while read -r device found_label filesystem type; do
    if [ "$found_label" = "$wanted" ]; then
      printf '%s\t%s\t%s\n' "$device" "$filesystem" "$type"
    fi
  done
}

printf 'Waiting for %s on Fern...\n' "$label"
for _ in $(seq 1 60); do
  if [ -n "$(volumes "$other")" ]; then
    printf 'wrong half connected: found %s while expecting %s\n' "$other" "$label" >&2
    exit 1
  fi
  mapfile -t matches < <(volumes "$label")
  if [ "${#matches[@]}" -gt 1 ]; then
    printf 'refusing duplicate %s volumes\n' "$label" >&2
    exit 1
  fi
  [ "${#matches[@]}" -eq 0 ] || break
  sleep 1
done

[ "${#matches[@]}" -eq 1 ] || { printf '%s did not appear\n' "$label" >&2; exit 1; }
IFS=$'\t' read -r device filesystem type <<< "${matches[0]}"
[ "$filesystem" = vfat ] || { printf 'refusing filesystem %s on %s\n' "$filesystem" "$device" >&2; exit 1; }
[ "$type" = disk ] || { printf 'refusing device type %s on %s\n' "$type" "$device" >&2; exit 1; }
case "$device" in /dev/*) ;; *) printf 'refusing device path %s\n' "$device" >&2; exit 1 ;; esac

mountpoint=$(findmnt -rn -S "$device" -o TARGET || true)
if [ -z "$mountpoint" ]; then
  mountpoint=/mnt/$mount_name
  sudo mkdir -p "$mountpoint"
  sudo mount -t vfat -o "uid=$(id -u),gid=$(id -g)" "$device" "$mountpoint"
fi
[ "$(findmnt -rn -S "$device" -o TARGET)" = "$mountpoint" ]
printf 'Mounted %s at %s.\n' "$label" "$mountpoint"
printf 'Copying firmware; do not touch the cable or power.\n'
cp "$firmware" "$mountpoint/flash.uf2"

printf 'Waiting for the bootloader drive to reboot...\n'
for _ in $(seq 1 15); do
  if ! lsblk "$device" >/dev/null 2>&1; then
    printf '%s firmware copy completed and the drive rebooted.\n' "$side"
    break
  fi
  sleep 1
done
lsblk "$device" >/dev/null 2>&1 && { printf '%s did not reboot after copying\n' "$label" >&2; exit 1; }

printf 'Waiting for %s normal USB mode...\n' "$product"
for _ in $(seq 1 30); do
  for product_file in /sys/bus/usb/devices/*/product; do
    [ -r "$product_file" ] || continue
    IFS= read -r found_product < "$product_file"
    if [ "$found_product" = "$product" ]; then
      printf '%s returned normally.\n' "$product"
      exit 0
    fi
  done
  sleep 1
done
printf '%s did not return in normal USB mode\n' "$product" >&2
exit 1
REMOTE
}

flash_side Right 'I + PgDn' GLV80RHBOOT GLV80LHBOOT 'Glove80 Right' glove80-right

printf '\nTurn the right half off and move the USB cable to the left half.\n'
read -r -p 'Press Enter after the right half is off and disconnected... ' _

flash_side Left 'Magic + E' GLV80LHBOOT GLV80RHBOOT 'Glove80 Left' glove80-left

progress 'Factory reset: left first'
printf 'Turn both halves off. Hold Magic + 3 on the left, switch it on, hold 5 seconds, then switch it off.\n'
read -r -p 'Press Enter when the left reset is complete... ' _

progress 'Factory reset: right second'
printf 'Keep both halves off. Hold PgDn + 8 on the right, switch it on, hold 5 seconds, then switch it off.\n'
read -r -p 'Press Enter when the right reset is complete... ' _

progress 'Restore and pair'
printf 'Turn both halves on together and wait for them to pair.\n'
printf 'Test typing and briefly enable RGB to confirm both halves illuminate.\n'
read -r -p 'Press Enter after both halves work... ' _
printf 'Wait at least one minute before switching either half off.\n'
