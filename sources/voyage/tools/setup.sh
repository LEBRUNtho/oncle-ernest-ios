#!/bin/zsh
# Prépare le jeu 2 (Le Fabuleux Voyage) sur un Mac : extrait l'archive du CD et range les fichiers à plat pour ScummVM.
# Le moteur est COMMUN avec le jeu 1 : lancer d'abord ~/Documents/Créations/Programmation/Portage Oncle Ernest iOS/album-oncle-ernest-ios/tools/setup.sh
# (il construit ~/album-ernest-build/scummvm avec le patch de référence, qui contient aussi les réglages du jeu 2).
set -e
PROJ=${0:A:h:h}
G=${GAME2:-$HOME/album2-build}
mkdir -p $G/data $G/game/resource $G/saves
cd $G
[ -f jeu-02764-Fabuleux_Voyage-pcwin/Voyage.iso ] || 7zz x -y $PROJ/original/Fabuleux_Voyage-pcwin.7z >/dev/null
[ -f data/voyage2.MPX ] || (cd data && bsdtar -xf ../jeu-02764-Fabuleux_Voyage-pcwin/Voyage.iso)
# ScummVM veut voyage.exe + voyage1.MPL + voyage2.MPX + resource/ (+ Video/ pour les films externes) ensemble
for f in data/voyage/data/*; do [ "${f:t}" = resource ] || ln -sf $G/$f game/; done
ln -sf $G/data/voyage2.MPX game/; ln -sfn $G/data/Video game/Video
for f in data/voyage/data/resource/* data/9598me/data/resource/bitmap.r95; do ln -sf $G/$f game/resource/; done
cat > $G/scummvm.ini <<INI
[scummvm]
savepath=$G/saves
vsync=false
album_touch_snap=28
album_remote=true
INI
cat > $G/run.sh <<'RUN'
#!/bin/zsh
# Lance le jeu 2 dans le ScummVM patché commun ; journal /tmp/ernest_run.log ; télécommande /tmp/ernest_cmd (cmd.sh du jeu 1)
cd ~/album-ernest-build/scummvm
exec ./scummvm --config=$HOME/album2-build/scummvm.ini -p $HOME/album2-build/game -d ${1:-1} --debugflags=all mtropolis:albert2 > /tmp/ernest_run.log 2>&1
RUN
chmod +x $G/run.sh
cp "$(dirname "$0")"/to_album.sh "$(dirname "$0")"/sim_voyage.sh "$(dirname "$0")"/sim_variantes.sh $G/ 2>/dev/null; chmod +x $G/*.sh
echo "OK. Lancer : $G/run.sh (en tâche de fond), piloter avec ~/album-ernest-build/cmd.sh"
