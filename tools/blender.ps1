# Run a Blender Python script headless. Usage: tools\blender.ps1 tools/blender/props/example_crate.py [args after --]
param([Parameter(Mandatory, Position = 0)][string]$Script, [Parameter(ValueFromRemainingArguments)][string[]]$Rest)
Set-Location (Split-Path $PSScriptRoot -Parent)
$exe = (Get-Command blender -ErrorAction SilentlyContinue).Source
if (-not $exe) { $exe = (Get-ChildItem "C:\Program Files\Blender Foundation\Blender*\blender.exe" | Sort-Object FullName -Descending | Select-Object -First 1).FullName }
& $exe --background --factory-startup --python $Script -- @Rest 2>&1 | ForEach-Object { "$_" } |
    Where-Object { $_ -match 'EXPORT|CONTACT|FLOAT|Error|Traceback|File "|Exception|error:' }
