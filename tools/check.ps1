# Project checks: Godot syntax check of every script, file-length rule (AGENTS.md 3.1), optional .glb validation.
# Usage: tools\check.ps1 [-Models]   (-Models also runs gltf-transform validate on models/generated/*.glb)
param([switch]$Models)
Set-Location (Split-Path $PSScriptRoot -Parent)
$bad = 0
Get-ChildItem scripts, tools -Recurse -Filter *.gd | ForEach-Object {
    $rel = $_.FullName.Substring((Get-Location).Path.Length + 1) -replace '\\', '/'
    $out = & godot --headless --path . --check-only --script $rel 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "SYNTAX  $rel"
        $out | Where-Object { $_ -match 'SCRIPT ERROR|Parse Error' } | Select-Object -First 3 | ForEach-Object { Write-Host "        $_" }
        $bad++
    }
}
Get-ChildItem scripts -Recurse -Filter *.gd | ForEach-Object {
    $n = (Get-Content $_.FullName | Measure-Object -Line).Lines
    if ($n -gt 150) { Write-Host ("LONG    {0,4} lines  {1}" -f $n, $_.FullName.Substring((Get-Location).Path.Length + 1)) }
}
if ($Models) {
    Get-ChildItem models\generated -Filter *.glb -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "--- $($_.Name)"; & gltf-transform validate $_.FullName 2>&1 | Select-Object -Last 8
    }
}
if ($bad -eq 0) { Write-Host "syntax OK" } else { Write-Host "$bad script(s) failed"; exit 1 }
