@echo off
cd /d "%~dp0"
if not exist journaux mkdir journaux
if exist corps_paquet.zip (
  echo Deballage du paquet des corps...
  "%SystemRoot%\System32\tar.exe" -xf corps_paquet.zip -C . > journaux\corps_paquet.txt 2>&1
  move /y corps_paquet.zip journaux\corps_paquet_applique.zip > nul
)
echo Preparation des corps : un Python a part et les donnees de MakeHuman et MPFB2, dans le dossier corps.
echo Quelques minutes (telechargements). La fenetre se ferme toute seule.
> journaux\corps_preparer.txt echo debut %date% %time%
set "PY="
if exist corps\python_chemin.txt set /p PY=<corps\python_chemin.txt
if not defined PY for /f "delims=" %%p in ('py -3 -c "import sys;print(sys.executable)" 2^>nul') do set "PY=%%p"
if not defined PY for /f "delims=" %%p in ('python -c "import sys;print(sys.executable)" 2^>nul') do set "PY=%%p"
if not defined PY (
  >> journaux\corps_preparer.txt echo PAS_DE_PYTHON
  goto fin
)
>> journaux\corps_preparer.txt echo PYTHON_DU_PC %PY%
"%PY%" -X utf8 corps\preparer_corps.py %* >> journaux\corps_preparer.txt 2>&1
:fin
>> journaux\corps_preparer.txt echo FINI %errorlevel% %date% %time%
