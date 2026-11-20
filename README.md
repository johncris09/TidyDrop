# TidyDrop

A tiny, safe file organizer that sweeps a cluttered folder (like your **Downloads**) into clean category subfolders by file type — Images, PDFs, Spreadsheets, Videos, and more.

Works on **Windows** (double-click or PowerShell) and anywhere with **Bash** (Git Bash, Linux, macOS).

## Features

- **Safe by design** — only top-level files are moved; your existing subfolders are never touched.
- **Never overwrites** — name conflicts are skipped and reported, not clobbered.
- **Dry-run mode** — preview exactly what will move/remove before committing.
- **Screenshots split out** — files named `Screenshot *.png` get their own subfolder.
- **Removes empty folders** — after sorting, leftover empty folders are cleaned up (deepest-first, so nested empties collapse too). Hidden folders like `.git` are never touched; a folder holding only `desktop.ini`/`Thumbs.db` counts as empty. Opt out with `-KeepEmpty` / `--keep-empty`.
- **Nothing is lost** — unknown file types go into an `Other/` folder.
- **Runs on any folder or drive** (e.g. `E:\`), not just Downloads.

## Categories

`Images` · `Images/Screenshots` · `PDFs` · `Office-Documents` · `Spreadsheets` · `SQL-Databases` · `Videos` · `Audio-Music` · `Archives` · `Torrents` · `Installers` · `Code-and-Config` · `Notes-and-Text` · `Other`

## Usage

### Windows — double-click (easiest)

1. Copy **`TidyDrop.bat`** and **`organize.ps1`** (both, together) into the folder you want to organize.
2. Double-click **`TidyDrop.bat`**.
3. Choose **Preview** (dry run, moves nothing) or **Organize now**.

The `.bat` always organizes the folder it lives in, and uses `-ExecutionPolicy Bypass` so it works even when Windows blocks `.ps1` double-clicks.

### Windows — PowerShell (point it anywhere)

```powershell
.\organize.ps1 -DryRun                   # preview the current folder
.\organize.ps1                           # organize the current folder
.\organize.ps1 -Target "E:\Stuff" -DryRun
.\organize.ps1 -Target "E:\Stuff"
.\organize.ps1 -Into "Organized"         # custom container folder name
.\organize.ps1 -KeepEmpty                # don't delete leftover empty folders
```

### Bash (Git Bash / Linux / macOS)

```bash
bash organize.sh --dry-run               # preview the current folder
bash organize.sh                         # organize the current folder
bash organize.sh "/e/Stuff" --dry-run
bash organize.sh "/e/Stuff"
bash organize.sh --into Organized
bash organize.sh --keep-empty            # don't delete leftover empty folders
```

## Which files do I need? (organizing another drive)

You do **not** need all three files — they're three ways to run the same tool.

| File | What it is | Needs a companion? |
|------|-----------|--------------------|
| `organize.ps1` | The actual Windows program | **Standalone** |
| `TidyDrop.bat` | A double-click launcher that runs `organize.ps1` | **Needs `organize.ps1` beside it** |
| `organize.sh`  | Same program, for Git Bash / Linux / macOS | **Standalone** |

To organize another drive (e.g. `E:\`), pick one approach:

- **Just type commands** → you only need **`organize.ps1`**. Keep it anywhere and aim it at any path; no copying into the drive required:
  ```powershell
  .\organize.ps1 -Target "E:\SomeFolder" -DryRun
  .\organize.ps1 -Target "E:\SomeFolder"
  ```
- **Prefer double-clicking** → copy **two** files together (`TidyDrop.bat` + `organize.ps1`) into the folder you want to organize, then double-click the `.bat`. The `.bat` won't work without `organize.ps1` next to it.
- **Using Git Bash** → you only need **`organize.sh`**:
  ```bash
  bash organize.sh "/e/SomeFolder" --dry-run
  bash organize.sh "/e/SomeFolder"
  ```

**Bottom line:** never all three at once. On Windows, `organize.ps1` is the only always-required file; `organize.sh` is only for Bash users.

## ⚠️ Caution about drive roots

Organizing a **data drive** like `E:\` is fine. **Do not** run it on the root of your system drive `C:\` — it holds Windows system files. Organize specific folders instead (e.g. `C:\Users\You\Downloads`). Always run a `--dry-run` / `-DryRun` first on any new location.

## How it decides

Files are sorted by their extension into the categories above. The grouping lives in one place in each script (`category_for` in `organize.sh`, `Get-Category` in `organize.ps1`) — easy to tweak if you want different buckets.

## License

MIT — see [LICENSE](LICENSE).
