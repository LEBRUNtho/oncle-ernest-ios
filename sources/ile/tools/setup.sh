#!/bin/zsh
# Prépare le jeu 3 (L'Île Mystérieuse) sur un Mac : extrait l'archive du CD, l'ISO, puis le dossier de données PC caché dans
# l'installeur Wise, et range le tout à plat pour ScummVM dans ~/album3-build (hors iCloud).
# Le moteur est COMMUN avec les jeux 1 et 2 : lancer d'abord le setup.sh du jeu 1 (album-oncle-ernest-ios/tools/setup.sh),
# qui construit ~/album-ernest-build/scummvm avec le patch de référence (il contient aussi les réglages du jeu 3).
set -e
PROJ=${0:A:h:h}
G=${GAME3:-$HOME/album3-build}
mkdir -p $G/data $G/game/resource $G/saves
cd $G
[ -f Ile.iso ] || { 7zz x -y "$PROJ/original/Ile_Mysterieuse-pcwin.7z" >/dev/null; mv jeu-02914-*/l*/Ile.iso Ile.iso; rm -rf jeu-02914-*; }
[ -f data/ile_myst2.MPX ] || (cd data && bsdtar -xf ../Ile.iso)
# ⚠️ sur ce CD, ile_myst/data ne contient qu'un faux fichier : les vrais fichiers sont dans install.exe (Wise)
[ -f game/ile_myst1.MPL ] || python3 "$PROJ/tools/wise_extract.py" data/install.exe game
# ScummVM veut Ile_myst.exe + ile_myst1.MPL + ile_myst2.MPX + resource/ (+ Video/ pour les films externes) ensemble
ln -sf $G/data/ile_myst2.MPX game/; ln -sfn $G/data/Video game/Video
ln -sf $G/data/9598me/data/resource/bitmap.r95 game/resource/    # version 95/98/ME du plugin Bitmap (celle attendue ; la « xp » diffère)
cat > $G/scummvm.ini <<INI
[scummvm]
savepath=$G/saves
vsync=false
album_touch_snap=28
album_remote=true
INI
cat > $G/run.sh <<'RUN'
#!/bin/zsh
# Lance le jeu 3 dans le ScummVM patché commun ; journal /tmp/ernest_run.log ; télécommande /tmp/ernest_cmd (cmd.sh du jeu 1)
cd ~/album-ernest-build/scummvm
exec ./scummvm --config=$HOME/album3-build/scummvm.ini -p $HOME/album3-build/game -d ${1:-1} --debugflags=all mtropolis:albert3 > /tmp/ernest_run.log 2>&1
RUN
chmod +x $G/run.sh
cp "$PROJ"/tools/to_album.sh "$PROJ"/tools/sim_ile.sh "$PROJ"/tools/sim_variantes.sh $G/ 2>/dev/null; chmod +x $G/*.sh
echo "OK. Lancer : $G/run.sh (en tâche de fond), piloter avec ~/album-ernest-build/cmd.sh"
