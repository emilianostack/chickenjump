@echo off
for %%G in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v*_win64.exe") do set "GODOT=%%~fG"
start "" "%GODOT%" --path "%~dp0."
