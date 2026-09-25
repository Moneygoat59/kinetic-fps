$desktop = [Environment]::GetFolderPath('Desktop')
$godotExe = 'C:\Users\Isaac\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\godot.exe'
$projectDir = 'C:\Users\Isaac\kinetic-fps'
$gameIco = "$projectDir\textures\kinetic_fps.ico"
$bunkerIco = "$projectDir\textures\outpost_73.ico"

$wsh = New-Object -ComObject WScript.Shell

$shortcuts = @(
    @{
        Name = "Kinetic FPS.lnk"
        Target = $godotExe
        Args = "--path `"$projectDir`""
        WorkDir = $projectDir
        Icon = "$gameIco,0"
        Desc = "Play Kinetic FPS"
    },
    @{
        Name = "Kinetic FPS - Godot Editor.lnk"
        Target = $godotExe
        Args = "-e --path `"$projectDir`""
        WorkDir = $projectDir
        Icon = "$godotExe,0"
        Desc = "Open Kinetic FPS in Godot 4 Editor"
    },
    @{
        Name = "Kinetic FPS - Bunker & Machinery Showroom.lnk"
        Target = $godotExe
        Args = "--path `"$projectDir`" scenes/dev/model_viewer.tscn"
        WorkDir = $projectDir
        Icon = "$bunkerIco,0"
        Desc = "Inspect Outpost 73 Bunker & Speculative Machinery Showroom"
    },
    @{
        Name = "Kinetic FPS - 3D Asset Gallery.lnk"
        Target = $godotExe
        Args = "--path `"$projectDir`" scenes/dev/model_gallery.tscn"
        WorkDir = $projectDir
        Icon = "$gameIco,0"
        Desc = "Browse Kinetic FPS 3D Asset Catalog"
    }
)

foreach ($sc in $shortcuts) {
    $lnkPath = Join-Path $desktop $sc.Name
    $item = $wsh.CreateShortcut($lnkPath)
    $item.TargetPath = $sc.Target
    $item.Arguments = $sc.Args
    $item.WorkingDirectory = $sc.WorkDir
    $item.IconLocation = $sc.Icon
    $item.Description = $sc.Desc
    $item.Save()
    Write-Host "Created shortcut: $lnkPath"
}
