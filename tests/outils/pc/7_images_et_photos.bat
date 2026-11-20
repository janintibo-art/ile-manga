@echo off
cd /d "%~dp0"
if not exist journaux mkdir journaux
rem V187 : de nouvelles images (textures) : Godot doit les preparer avant de lancer le jeu
if exist maj.zip (
  echo Mise a jour de la copie du jeu...
  "%SystemRoot%\System32\tar.exe" -xf maj.zip -C . > journaux\maj.txt 2>&1
  move /y maj.zip journaux\maj_appliquee.zip > nul
)
echo Godot prepare les nouvelles images (une a deux minutes)...
> journaux\importer.txt echo debut %date% %time%
"%~dp0..\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0jeu" --import >> journaux\importer.txt 2>&1
>> journaux\importer.txt echo FINI %errorlevel% %date% %time%
call "%~dp03_photos.bat"
