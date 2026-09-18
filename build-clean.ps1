<#
.SYNOPSIS
    Removes all stray bin/obj/build folders anywhere in the repo, then rebuilds.

.DESCRIPTION
    Ordinary `dotnet clean` / deleting the top-level obj and bin only cleans the
    current project's own output. If a leftover obj/bin folder exists somewhere
    else in the tree (e.g. under src/, left behind by a past project move), its
    generated AssemblyInfo files can get picked up by the default source glob
    and cause duplicate-attribute build errors (CS0579) or other weird failures.

    Run this whenever a build produces errors that don't make sense (duplicate
    symbols/attributes, stale references, etc.) before spending time debugging.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Searching for bin/obj/build folders under $root ..." -ForegroundColor Cyan

$dirs = Get-ChildItem -Path $root -Recurse -Directory -Force |
    Where-Object { $_.Name -in @("bin", "obj", "build") }

if ($dirs.Count -eq 0) {
    Write-Host "No stray build artifact folders found." -ForegroundColor Green
} else {
    foreach ($dir in $dirs) {
        Write-Host "Removing $($dir.FullName)" -ForegroundColor Yellow
        Remove-Item -Path $dir.FullName -Recurse -Force
    }
}

Write-Host "`nRunning dotnet build..." -ForegroundColor Cyan
Push-Location $root
try {
    dotnet build
} finally {
    Pop-Location
}
