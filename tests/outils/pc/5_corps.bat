@echo off
cd /d "%~dp0"
if not exist journaux mkdir journaux
echo Fabrication des corps des habitants (de 5 a 20 minutes). La fenetre se ferme toute seule.
> journaux\corps.txt echo debut %date% %time%
if not exist corps\venv\Scripts\python.exe (
  >> journaux\corps.txt echo PAS_DE_VENV : lancer d'abord 4_corps_preparer.bat
  goto fin
)
"%~dp0corps\venv\Scripts\python.exe" -X utf8 corps\lancer_corps.py corps >> journaux\corps.txt 2>&1
:fin
>> journaux\corps.txt echo FINI %errorlevel% %date% %time%
