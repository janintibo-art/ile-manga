@echo off
cd /d "%~dp0"
if not exist journaux mkdir journaux
echo Godot prepare le jeu une premiere fois (quelques minutes)...
> journaux\preparer.txt echo debut %date% %time%
"%~dp0..\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0jeu" --import >> journaux\preparer.txt 2>&1
>> journaux\preparer.txt echo FINI %errorlevel% %date% %time%
