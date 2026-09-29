# One command for the whole verification pass (AGENTS.md 5): tools\check.ps1, tools\smoke.ps1, then every gameplay test
# hook tools/exec/check_*.gd (run through capture.ps1 -Exec: needs a GPU window, each opens one briefly).
# A hook passes when it printed at least one `CHECK ok` line, no `CHECK FAIL` line and no SCRIPT ERROR.
# Usage: tools\test.ps1 [-Only routes] [-NoSmoke] [-NoCheck]    (-Only: run the hooks whose name contains it)
param([string]$Only = "", [switch]$NoSmoke, [switch]$NoCheck)
Set-Location (Split-Path $PSScriptRoot -Parent)
$start = Get-Date
$failures = @()

function Step([string]$name, [scriptblock]$run) {
    $t = Get-Date
    $ok = & $run
    Write-Host ("{0,-5} {1}  ({2:N1} s)" -f $(if ($ok) { "PASS" } else { "FAIL" }), $name, ((Get-Date) - $t).TotalSeconds)
    if (-not $ok) { $script:failures += $name }
}

if (-not $NoCheck) {
    Step "check" {
        $out = & "$PSScriptRoot\check.ps1" 6>&1 | ForEach-Object { "$_" }
        $out | Where-Object { $_ -match '^(SYNTAX|TOO LONG)|^\s+(SCRIPT ERROR|at:)' } | ForEach-Object { Write-Host "      $_" }
        $LASTEXITCODE -eq 0
    }
}
if (-not $NoSmoke) {
    Step "smoke" {
        $out = & "$PSScriptRoot\smoke.ps1" 6>&1 | ForEach-Object { "$_" }
        $out | Where-Object { $_ -match '^SMOKE|ERROR' } | Select-Object -First 8 | ForEach-Object { Write-Host "      $_" }
        $LASTEXITCODE -eq 0 -and ($out -match '^SMOKE OK')
    }
}
New-Item -ItemType Directory -Force shots\test | Out-Null
Get-ChildItem tools\exec -Filter check_*.gd | Where-Object { $_.BaseName -like "*$Only*" } | ForEach-Object {
    $hook = $_.BaseName
    Step $hook {
        $out = & "$PSScriptRoot\capture.ps1" -Scene res://scenes/levels/dead_forest.tscn -Exec "res://tools/exec/$hook.gd" `
            -Out "shots/test/$hook" -Cam 0,5,0 -Look 0,0,-10 -Wait 3 -NoUi 2>&1 | ForEach-Object { "$_" }
        $okLines = @($out | Where-Object { $_ -match '^CHECK ok' })
        $bad = @($out | Where-Object { $_ -match '^CHECK FAIL|SCRIPT ERROR' })
        $bad | ForEach-Object { Write-Host "      $_" }
        if ($okLines.Count -eq 0) { Write-Host "      no CHECK lines: the hook did not run to the end" }
        Write-Host ("      {0} check(s) ok" -f $okLines.Count)
        $okLines.Count -gt 0 -and $bad.Count -eq 0
    }
}
$secs = ((Get-Date) - $start).TotalSeconds
if ($failures.Count -eq 0) { Write-Host ("ALL PASS  ({0:N0} s)" -f $secs) }
else { Write-Host ("FAILED: {0}  ({1:N0} s)" -f ($failures -join ", "), $secs); exit 1 }
