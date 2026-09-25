# Headless smoke test. Usage: tools\smoke.ps1 [-Scene res://...] [-Frames 300]
# Prints SMOKE line plus real script errors/warnings; hides exit-time RID/ObjectDB leak noise.
param([string]$Scene = "res://scenes/levels/dead_forest.tscn", [int]$Frames = 300)
Set-Location (Split-Path $PSScriptRoot -Parent)
$out = & godot --headless --path . --script tools/smoke_test.gd -- --scene $Scene --frames $Frames 2>&1 | ForEach-Object { "$_" }
$noise = 'leaked at exit|Leaked instance dependency|Pages in use|ObjectDB instances|resources still in use|~Dependency|~PagedAllocator|cleanup \(|clear \(|^\s+at: (~|cleanup|clear)'
$out | Where-Object { $_ -notmatch $noise -and $_.Trim() -ne '' } | ForEach-Object { $_ }
if (-not ($out | Select-String 'SMOKE OK')) { Write-Host "SMOKE FAILED"; exit 1 }
