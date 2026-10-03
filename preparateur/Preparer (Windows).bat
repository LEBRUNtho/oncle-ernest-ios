@echo off
chcp 65001 >nul
rem Double-cliquer, puis glisser l'image du CD (.iso, .7z, .zip) ou son dossier dans la fenêtre et appuyer sur Entrée.
cd /d "%~dp0"
where py >nul 2>nul && (set PY=py -3) || (set PY=python)
%PY% --version >nul 2>nul || (echo Python 3 est necessaire : https://www.python.org/downloads/ & pause & exit /b 1)
if not exist .venv (
  echo Premiere utilisation : installation des outils, une minute...
  %PY% -m venv .venv && .venv\Scripts\pip -q install -r requirements.txt
)
set "CD=%~1"
if "%CD%"=="" set /p "CD=Glissez ici l'image du CD (ou son dossier), puis appuyez sur Entree : "
set "CD=%CD:"=%"
.venv\Scripts\python preparer.py "%CD%" "%cd%\apps" && explorer apps
echo.
pause
