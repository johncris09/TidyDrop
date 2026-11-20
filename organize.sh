#!/usr/bin/env bash
#
# organize.sh — sort loose files in a folder into category subfolders by type.
#
# Usage:
#   ./organize.sh [TARGET_DIR] [--dry-run] [--into DIRNAME] [--keep-empty]
#
#   TARGET_DIR    Folder to organize. Default: current directory.
#   --dry-run     Show what WOULD move/remove, without touching anything.
#   --into NAME   Name of the container folder for sorted files.
#                 Default: "_Sorted".
#   --keep-empty  Do NOT delete leftover empty folders (they are removed
#                 by default once sorting is done).
#   --yes, -y     Skip the "type YES" confirmation (for scripts/automation).
#
# Behavior / safety:
#   - A real run asks you to type YES (showing the target path) before it
#     changes anything. Dry runs and --yes skip this prompt.
#   - Only top-level files are moved (existing subfolders are left untouched).
#   - Uses `mv -n` so an existing file is never overwritten.
#   - Screenshots (files named "Screenshot *.png") get their own subfolder.
#   - System files (desktop.ini, Thumbs.db, the script itself) are skipped.
#   - Extensionless files are left where they are.
#   - After sorting, empty folders are removed (deepest-first, so nested
#     empties collapse too). Hidden folders (.git, .claude ...) are never
#     touched. A folder holding only desktop.ini/Thumbs.db counts as empty.
#
set -euo pipefail

# ---- parse arguments --------------------------------------------------------
TARGET="."
DRYRUN=0
CONTAINER="_Sorted"
KEEPEMPTY=0
ASSUMEYES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRYRUN=1; shift ;;
    --keep-empty) KEEPEMPTY=1; shift ;;
    --yes|-y)     ASSUMEYES=1; shift ;;
    --into)       CONTAINER="${2:?--into needs a name}"; shift 2 ;;
    -h|--help)
      sed -n '2,26p' "$0"; exit 0 ;;
    -*)
      echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      TARGET="$1"; shift ;;
  esac
done

cd "$TARGET" || { echo "Cannot enter: $TARGET" >&2; exit 1; }
SELF="$(basename "$0")"

# ---- confirmation (real runs only) ------------------------------------------
if [[ "$DRYRUN" -eq 0 && "$ASSUMEYES" -eq 0 ]]; then
  echo "About to organize this folder:"
  echo "    $(pwd)"
  echo "Files will be moved into ./$CONTAINER/ and empty folders removed."
  printf "Type YES (in capitals) to proceed: "
  reply=""
  if ! { read -r reply < /dev/tty; } 2>/dev/null; then
    read -r reply || reply=""
  fi
  if [[ "$reply" != "YES" ]]; then
    echo "Aborted. Nothing was changed."
    exit 0
  fi
  echo
fi

# ---- map an extension to a category folder ----------------------------------
category_for() {
  local f="$1" ext
  # Screenshots first
  if [[ "$f" == Screenshot\ * && "${f,,}" == *.png ]]; then
    echo "Images/Screenshots"; return
  fi
  ext="${f##*.}"; ext="${ext,,}"
  case "$ext" in
    jpg|jpeg|png|webp|gif|bmp|svg|psd|tiff) echo "Images" ;;
    pdf)                                     echo "PDFs" ;;
    doc|docx|pptx|ppt|odt|rtf)               echo "Office-Documents" ;;
    xls|xlsx|csv|ods)                        echo "Spreadsheets" ;;
    sql|db|sqlite)                           echo "SQL-Databases" ;;
    mp4|mov|avi|mkv|webm|wmv)                echo "Videos" ;;
    mp3|wav|flac|m4a|mid|gp|ogg)             echo "Audio-Music" ;;
    zip|rar|7z|tar|gz)                       echo "Archives" ;;
    torrent)                                 echo "Torrents" ;;
    exe|msi|apk|crx|dmg)                     echo "Installers" ;;
    txt|md)                                  echo "Notes-and-Text" ;;
    py|js|ts|json|jar|bundle|ini|ttf|htm|html|mpd|log|srt|xml|yml|yaml) echo "Code-and-Config" ;;
    *)                                       echo "Other" ;;
  esac
}

# ---- do the work ------------------------------------------------------------
moved=0; skipped=0
declare -A counts

while IFS= read -r -d '' path; do
  f="${path#./}"
  case "$f" in
    desktop.ini|Thumbs.db|"$SELF"|"$CONTAINER") continue ;;
  esac
  [[ "$f" == *.* ]] || { skipped=$((skipped + 1)); continue; }   # no extension -> leave

  cat="$(category_for "$f")"
  dest="$CONTAINER/$cat"

  if [[ "$DRYRUN" -eq 1 ]]; then
    printf '  %-22s <- %s\n' "$cat" "$f"
  else
    mkdir -p "$dest"
    mv -n -- "$f" "$dest/"
  fi
  counts["$cat"]=$(( ${counts["$cat"]:-0} + 1 ))
  moved=$((moved + 1))
done < <(find . -maxdepth 1 -type f -print0)

# ---- remove empty folders ---------------------------------------------------
emptied=0
if [[ "$KEEPEMPTY" -eq 0 ]]; then
  while IFS= read -r -d '' d; do
    case "$d" in
      ./"$CONTAINER"|./"$CONTAINER"/*) continue ;;   # never the sorted container
      *"/."*) continue ;;                            # skip hidden folders (.git ...)
    esac
    # Empty apart from Windows cruft?
    keep=0
    shopt -s nullglob dotglob
    for e in "$d"/*; do
      b="${e##*/}"
      [[ "$b" == "desktop.ini" || "$b" == "Thumbs.db" ]] && continue
      keep=1; break
    done
    shopt -u nullglob dotglob
    [[ $keep -eq 1 ]] && continue
    if [[ "$DRYRUN" -eq 1 ]]; then
      echo "  would remove empty folder: ${d#./}"
    else
      rm -f -- "$d/desktop.ini" "$d/Thumbs.db" 2>/dev/null || true
      rmdir -- "$d" 2>/dev/null || true
    fi
    emptied=$((emptied + 1))
  done < <(find . -mindepth 1 -depth -type d -print0)
fi

# ---- summary ----------------------------------------------------------------
echo
if [[ "$DRYRUN" -eq 1 ]]; then
  echo "DRY RUN — nothing was moved. $moved file(s) would be sorted:"
else
  echo "Done. Sorted $moved file(s) into ./$CONTAINER/"
fi
for cat in $(printf '%s\n' "${!counts[@]}" | sort); do
  printf '  %5d  %s\n' "${counts[$cat]}" "$cat"
done
if [[ "$KEEPEMPTY" -eq 0 && "$emptied" -gt 0 ]]; then
  if [[ "$DRYRUN" -eq 1 ]]; then
    echo "  (plus $emptied empty folder(s) would be removed)"
  else
    echo "Removed $emptied empty folder(s)."
  fi
fi
