#!/bin/bash
# Double-cliquer, puis glisser l'image du CD (.iso, .7z, .zip) ou son dossier dans la fenêtre et appuyer sur Entrée.
cd "$(dirname "$0")"
command -v python3 >/dev/null || { echo "Python 3 est nécessaire : https://www.python.org/downloads/"; read -r; exit 1; }
[ -d .venv ] || { echo "Première utilisation : installation des outils (une minute)..."; python3 -m venv .venv && .venv/bin/pip -q install -r requirements.txt; }
CD="$1"; [ -n "$CD" ] || { echo "Glissez ici l'image du CD (ou son dossier), puis appuyez sur Entrée :"; read -r CD; CD="${CD%\'}"; CD="${CD#\'}"; CD="${CD//\\ / }"; }
.venv/bin/python preparer.py "$CD" "$(pwd)/apps" && open apps
echo; echo "Appuyez sur Entrée pour fermer."; read -r
