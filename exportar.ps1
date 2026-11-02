# Gera os pacotes do itch.io em build\: ChickenJump-web.zip e ChickenJump-windows.zip.
# Rode de novo sempre que mudar o jogo.
$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
$packages = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
$godot = (Get-ChildItem $packages -Filter 'Godot_v*_win64_console.exe' | Select-Object -First 1).FullName

function Export-Preset([string]$Preset, [string]$Target) {
    New-Item -ItemType Directory -Force (Split-Path "$project\$Target") | Out-Null
    & $godot --headless --path $project --export-release $Preset $Target 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Falha ao exportar $Preset" }
}

function Pack([string]$Folder, [string]$Zip) {
    Get-ChildItem "$project\build\$Folder" -Filter *.import | Remove-Item -Confirm:$false
    Copy-Item "$project\LICENSES.txt" "$project\build\$Folder\" -Force
    Remove-Item "$project\build\$Zip" -ErrorAction SilentlyContinue
    Compress-Archive -Path "$project\build\$Folder\*" -DestinationPath "$project\build\$Zip"
    "{0}: {1} MB" -f $Zip, [math]::Round((Get-Item "$project\build\$Zip").Length / 1MB, 1)
}

Export-Preset 'Web' 'build/web/index.html'
Export-Preset 'Windows' 'build/windows/ChickenJump.exe'
Pack 'web' 'ChickenJump-web.zip'
Pack 'windows' 'ChickenJump-windows.zip'
