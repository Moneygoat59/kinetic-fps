# Screenshot wrapper. Usage:
#   tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Out shots/forest -Cam 0,30,60 -Look 0,0,0
#   tools\capture.ps1 -Scene res://models/bunker_small.glb -Out shots/bunker -Views front,right,top,iso -Dist 12 -Lit
param([Parameter(Mandatory)][string]$Scene, [string]$Out = "shots/capture", [double[]]$Cam, [double[]]$Look = @(0,1,0),
      [string[]]$Views, [double]$Dist = 8, [int]$Frames = 30, [string]$Size = "1280x720", [switch]$Lit, [switch]$Fit, [switch]$NoUi, [double]$Wait = 0, [string]$Exec)
Set-Location (Split-Path $PSScriptRoot -Parent)
$a = @("--scene", $Scene, "--out", $Out, "--look", ($Look -join ","), "--frames", $Frames, "--size", $Size)
if ($Cam) { $a += @("--cam", ($Cam -join ",")) }
if ($Views) { $a += @("--views", ($Views -join ",")) }
if ($Lit) { $a += "--lit" }
if ($Fit) { $a += "--fit" }
if ($NoUi) { $a += "--no-ui" }
if ($Wait -gt 0) { $a += @("--wait", $Wait) }
if ($PSBoundParameters.ContainsKey('Dist')) { $a += @("--dist", $Dist) }
if ($Exec) { $a += @("--exec", $Exec) }
$noise = 'leaked at exit|Leaked instance dependency|Pages in use|ObjectDB instances|resources still in use|~Dependency|~PagedAllocator|cleanup \(|clear \(|^\s+at: (~|cleanup|clear)'
& godot --path . --resolution $Size --script tools/capture.gd -- @a 2>&1 | ForEach-Object { "$_" } |
    Where-Object { $_ -notmatch $noise -and $_.Trim() -ne '' }
