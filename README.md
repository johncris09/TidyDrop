# TidyDrop

A tiny, safe file organizer that sweeps a cluttered folder (like your **Downloads**) into clean category subfolders by file type — Images, PDFs, Spreadsheets, Videos, and more.

Works on **Windows** (double-click or PowerShell) and anywhere with **Bash** (Git Bash, Linux, macOS).

## Features

- **Safe by design** — only top-level files are moved; your existing subfolders are never touched.
- **Never overwrites** — name conflicts are skipped and reported, not clobbered.
- **Dry-run mode** — preview exactly what will move before committing.
- **Screenshots split out** — files named `Screenshot *.png` get their own subfolder.
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
```

### Bash (Git Bash / Linux / macOS)

```bash
bash organize.sh --dry-run               # preview the current folder
bash organize.sh                         # organize the current folder
bash organize.sh "/e/Stuff" --dry-run
bash organize.sh "/e/Stuff"
bash organize.sh --into Organized
```

## ⚠️ Caution about drive roots

Organizing a **data drive** like `E:\` is fine. **Do not** run it on the root of your system drive `C:\` — it holds Windows system files. Organize specific folders instead (e.g. `C:\Users\You\Downloads`). Always run a `--dry-run` / `-DryRun` first on any new location.

## How it decides

Files are sorted by their extension into the categories above. The grouping lives in one place in each script (`category_for` in `organize.sh`, `Get-Category` in `organize.ps1`) — easy to tweak if you want different buckets.

## License

MIT — see [LICENSE](LICENSE).
