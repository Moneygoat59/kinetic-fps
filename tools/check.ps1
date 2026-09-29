# Project checks: Godot syntax check of every script (one process, class cache refreshed when needed), file size
# (AGENTS.md 3.1), optional .glb validation. Fails (exit 1) on a syntax error or a file over the hard limit.
# Usage: tools\check.ps1 [-Chains] [-Models]
#   File size counts every line: over 150 is a note (soft limit), over 250 fails unless grandfathered below.
#   -Chains lists the scripts that chain statements with ';' (AGENTS.md 3.1: unchain what you edit); otherwise one summary line.
#   -Models also runs gltf-transform validate on models/generated/*.glb.
param([switch]$Chains, [switch]$Models)
Set-Location (Split-Path $PSScriptRoot -Parent)
$SOFT = 150
$HARD = 250
$GRANDFATHERED = @('small_bunker.gd', 'megalevel_manager.gd', 'mech_enemy.gd', 'world_decorator.gd', 'drone_enemy.gd')
$STRINGS = '"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*'''
$bad = 0
# Godot resolves class_name globals from its class cache, which only the editor / an import refreshes. A script that adds or
# renames a class_name since the last refresh would make every script using it fail: refresh first (then mark it fresh).
$cache = '.godot\global_script_class_cache.cfg'
$stamp = if (Test-Path $cache) { (Get-Item $cache).LastWriteTime } else { [datetime]::MinValue }
$stale = @(Get-ChildItem scripts, tools -Recurse -Filter *.gd | Where-Object { $_.LastWriteTime -gt $stamp } |
    Where-Object { Select-String -Path $_.FullName -Pattern '^class_name\s' -Quiet })
if ($stale.Count -gt 0 -or -not (Test-Path $cache)) {
    Write-Host "CLASSES refreshing the class cache ($($stale.Count) script(s) with class_name changed)"
    & godot --headless --path . --import 2>&1 | Out-Null
    if (Test-Path $cache) { (Get-Item $cache).LastWriteTime = Get-Date }
}
# Syntax: every script compiled in one Godot process (tools/check_scripts.gd).
$out = & godot --headless --path . --script tools/check_scripts.gd 2>&1 | ForEach-Object { "$_" }
$failed = @($out | Where-Object { $_ -match '^SYNTAX' })
if ($failed.Count -gt 0 -or -not ($out -match '^CHECKED')) {
    $failed | ForEach-Object { Write-Host $_ }
    $out | Where-Object { $_ -match 'SCRIPT ERROR|^\s+at: GDScript' } | Select-Object -First 20 | ForEach-Object { Write-Host "        $($_.Trim())" }
    if (-not ($out -match '^CHECKED')) { Write-Host "SYNTAX  checker did not finish"; $out | Select-Object -Last 5 | ForEach-Object { Write-Host "        $_" } }
    $bad += [math]::Max($failed.Count, 1)
}
$chained = @()
Get-ChildItem scripts -Recurse -Filter *.gd | ForEach-Object {
    $rel = $_.FullName.Substring((Get-Location).Path.Length + 1)
    $lines = @(Get-Content $_.FullName)
    $n = $lines.Count
    if ($n -gt $HARD -and $GRANDFATHERED -notcontains $_.Name) {
        Write-Host ("TOO LONG {0,4} lines  {1}  (hard limit {2}: split it by responsibility)" -f $n, $rel, $HARD)
        $bad++
    } elseif ($n -gt $HARD) {
        Write-Host ("LEGACY  {0,4} lines  {1}" -f $n, $rel)
    } elseif ($n -gt $SOFT) {
        Write-Host ("LONG    {0,4} lines  {1}  (soft: one responsibility?)" -f $n, $rel)
    }
    $c = @($lines | Where-Object { (($_ -replace $STRINGS, '""') -replace '#.*$', '').TrimEnd().TrimEnd(';') -match ';' }).Count
    if ($c -gt 0) { $chained += , @($c, $rel) }
}
if ($chained.Count -gt 0) {
    $total = ($chained | ForEach-Object { $_[0] } | Measure-Object -Sum).Sum
    Write-Host ("CHAINED {0} script(s), {1} line(s) with ';'-chained statements{2}" -f $chained.Count, $total, $(if ($Chains) { ':' } else { ' (-Chains lists them)' }))
    if ($Chains) { $chained | Sort-Object { $_[0] } -Descending | ForEach-Object { Write-Host ("        {0,4}  {1}" -f $_[0], $_[1]) } }
}
if ($Models) {
    Get-ChildItem models\generated -Filter *.glb -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "--- $($_.Name)"; & gltf-transform validate $_.FullName 2>&1 | Select-Object -Last 8
    }
}
if ($bad -eq 0) { Write-Host "checks OK" } else { Write-Host "$bad check(s) failed"; exit 1 }
