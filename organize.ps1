<#
    organize.ps1 — sort loose files in a folder into category subfolders by type.

    Usage (PowerShell):
        .\organize.ps1                       # organize current folder
        .\organize.ps1 -DryRun               # preview only, change nothing
        .\organize.ps1 -Target "C:\path"     # organize another folder
        .\organize.ps1 -Into "Organized"     # custom container name
        .\organize.ps1 -KeepEmpty            # keep leftover empty folders

    Safety:
        - Only top-level files are moved; existing subfolders are untouched.
        - Never overwrites an existing file (conflicts are skipped + reported).
        - Screenshots ("Screenshot *.png") get their own subfolder.
        - Skips system files, the scripts themselves, and extensionless files.
        - After sorting, empty folders are removed (deepest-first). Hidden
          folders (.git, .claude ...) are never touched; a folder holding
          only desktop.ini/Thumbs.db counts as empty. Use -KeepEmpty to skip.
#>

[CmdletBinding()]
param(
    [string]$Target = ".",
    [switch]$DryRun,
    [string]$Into = "_Sorted",
    [switch]$KeepEmpty
)

$ErrorActionPreference = "Stop"

# Resolve and enter target folder
try   { $Target = (Resolve-Path -LiteralPath $Target).Path }
catch { Write-Host "Cannot find folder: $Target" -ForegroundColor Red; exit 1 }

$skipNames = @("desktop.ini","Thumbs.db","organize.ps1","organize.sh",
               "TidyDrop.bat")

function Get-Category($file) {
    if ($file.Name -like "Screenshot *" -and $file.Extension -ieq ".png") {
        return "Images\Screenshots"
    }
    switch -Regex ($file.Extension.TrimStart('.').ToLower()) {
        '^(jpg|jpeg|png|webp|gif|bmp|svg|psd|tiff)$' { "Images" }
        '^(pdf)$'                                    { "PDFs" }
        '^(doc|docx|pptx|ppt|odt|rtf)$'              { "Office-Documents" }
        '^(xls|xlsx|csv|ods)$'                       { "Spreadsheets" }
        '^(sql|db|sqlite)$'                          { "SQL-Databases" }
        '^(mp4|mov|avi|mkv|webm|wmv)$'               { "Videos" }
        '^(mp3|wav|flac|m4a|mid|gp|ogg)$'            { "Audio-Music" }
        '^(zip|rar|7z|tar|gz)$'                      { "Archives" }
        '^(torrent)$'                                { "Torrents" }
        '^(exe|msi|apk|crx|dmg)$'                    { "Installers" }
        '^(txt|md)$'                                 { "Notes-and-Text" }
        '^(py|js|ts|json|jar|bundle|ini|ttf|htm|html|mpd|log|srt|xml|yml|yaml)$' { "Code-and-Config" }
        default                                      { "Other" }
    }
}

$counts = @{}
$moved = 0
$conflicts = 0

Get-ChildItem -LiteralPath $Target -File | ForEach-Object {
    $file = $_
    if ($skipNames -contains $file.Name) { return }
    if (-not $file.Extension)            { return }   # extensionless -> leave

    $cat  = Get-Category $file
    $dest = Join-Path $Target (Join-Path $Into $cat)

    if ($DryRun) {
        "{0,-22} <- {1}" -f $cat, $file.Name | Write-Host
    } else {
        if (-not (Test-Path -LiteralPath $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
        $targetPath = Join-Path $dest $file.Name
        if (Test-Path -LiteralPath $targetPath) {
            Write-Host "SKIP (already exists): $($file.Name)" -ForegroundColor Yellow
            $conflicts++
            return
        }
        Move-Item -LiteralPath $file.FullName -Destination $dest
    }
    $counts[$cat] = ($counts[$cat] + 1)
    $moved++
}

# ---- remove empty folders ---------------------------------------------------
$emptied = 0
if (-not $KeepEmpty) {
    Get-ChildItem -LiteralPath $Target -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending |
        ForEach-Object {
            $dir = $_
            if ($dir.FullName -match '\\\.') { return }   # skip hidden (.git, .claude ...)
            if ($dir.FullName -like "*\$Into" -or $dir.FullName -like "*\$Into\*") { return }
            $remaining = Get-ChildItem -LiteralPath $dir.FullName -Force |
                Where-Object { $_.Name -notin @("desktop.ini","Thumbs.db") }
            if (-not $remaining) {
                if ($DryRun) {
                    Write-Host "would remove empty folder: $($dir.FullName)"
                } else {
                    Get-ChildItem -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Force -ErrorAction SilentlyContinue
                    Remove-Item -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue
                }
                $emptied++
            }
        }
}

Write-Host ""
if ($DryRun) {
    Write-Host "DRY RUN - nothing was changed. $moved file(s) would be sorted:" -ForegroundColor Cyan
} else {
    Write-Host "Done. Sorted $moved file(s) into .\$Into\" -ForegroundColor Green
    if ($conflicts -gt 0) {
        Write-Host "$conflicts file(s) skipped because a file with that name already existed." -ForegroundColor Yellow
    }
}
$counts.Keys | Sort-Object | ForEach-Object {
    "{0,5}  {1}" -f $counts[$_], $_ | Write-Host
}
if (-not $KeepEmpty -and $emptied -gt 0) {
    if ($DryRun) {
        Write-Host "  (plus $emptied empty folder(s) would be removed)"
    } else {
        Write-Host "Removed $emptied empty folder(s)." -ForegroundColor Green
    }
}
