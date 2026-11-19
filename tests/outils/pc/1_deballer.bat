@echo off
cd /d "%~dp0"
if not exist journaux mkdir journaux
if not exist jeu mkdir jeu
echo Deballage de la copie du jeu (1 a 2 minutes)...
> journaux\deballer.txt echo debut %date% %time%
for %%z in (paquets\jeu_*.zip) do (
  echo %%z
  >> journaux\deballer.txt echo %%z
  "%SystemRoot%\System32\tar.exe" -xf "%%z" -C jeu >> journaux\deballer.txt 2>&1
)
>> journaux\deballer.txt echo FINI %date% %time%
