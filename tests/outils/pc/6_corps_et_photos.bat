@echo off
cd /d "%~dp0"
rem V186 : les trois etapes a la suite : preparer les corps, les fabriquer, prendre les photos
call "%~dp04_corps_preparer.bat"
call "%~dp05_corps.bat"
call "%~dp03_photos.bat"
