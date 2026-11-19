@echo off
cd /d "%~dp0"
if not exist journaux mkdir journaux
if exist maj.zip (
  echo Mise a jour de la copie du jeu...
  "%SystemRoot%\System32\tar.exe" -xf maj.zip -C . > journaux\maj.txt 2>&1
  move /y maj.zip journaux\maj_appliquee.zip > nul
)
if not exist photos mkdir photos
echo Godot lance le jeu et prend les photos de controle (ne touchez a rien, la fenetre se ferme toute seule)...
> journaux\photos.txt echo debut %date% %time%
"%~dp0..\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0jeu" --xr-mode off --audio-driver Dummy --resolution 1600x900 >> journaux\photos.txt 2>&1
>> journaux\photos.txt echo FINI %errorlevel% %date% %time%
