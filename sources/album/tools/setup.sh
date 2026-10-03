#!/bin/zsh
# Reconstruit l'environnement de travail de l'Album sur un Mac neuf (Apple Silicon, Homebrew, Xcode COMPLET pour iOS).
# Pour l'IPA : le certificat de sideloading doit être dans le trousseau (voir build-ios.sh, IDENTITY).
# Usage : tools/setup.sh [dossier_de_travail]   (défaut : ~/album-ernest-build, HORS iCloud)
set -e
PROJ=${0:A:h:h}
WORK=${1:-$HOME/album-ernest-build}
SCUMMVM_COMMIT=be8894515085e26aa3392d76ef66a968ba104dca   # commit ScummVM sur lequel le patch a été fait (23/09/2026)

# Homebrew Apple Silicon en premier (sur le Mac, /usr/local/bin/brew est la version Intel : librairies x86_64)
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
echo "== Dépendances Homebrew"
brew install sdl2 freetype libpng jpeg-turbo libvorbis flac mad ffmpeg

mkdir -p $WORK/{data,game,saves}

echo "== Extraction de l'ISO (sans monter : hdiutil ne sait pas, c'est un ISO hybride Mac/PC)"
if [ ! -f $WORK/data/album422.MPX ]; then
  (cd $WORK/data && bsdtar -xf $PROJ/original/Album.iso)
fi

echo "== Dossier de jeu à plat (liens) : ScummVM veut MTPLAY95.EXE + album421.MPL + album422.MPX ensemble"
for f in $WORK/data/Album/Data/*; do ln -sf "$f" $WORK/game/; done
ln -sf $WORK/data/album422.MPX $WORK/game/

echo "== ScummVM (moteur mTropolis seul) + patch Album"
if [ ! -d $WORK/scummvm/.git ]; then
  git clone --filter=blob:none https://github.com/scummvm/scummvm.git $WORK/scummvm
fi
cd $WORK/scummvm
git checkout -q $SCUMMVM_COMMIT
git reset -q --hard $SCUMMVM_COMMIT
git apply $PROJ/tools/scummvm-album.patch
./configure --disable-all-engines --enable-engine=mtropolis --disable-debug --enable-release > /tmp/ernest_configure.log
make -j$(sysctl -n hw.ncpu) > /tmp/ernest_build.log 2>&1 || { tail -30 /tmp/ernest_build.log; exit 1; }

echo "== Config ScummVM isolée (rendu OpenGL = 32 bits dispo ; vsync coupé sinon le rendu se fige écran éteint)"
cat > $WORK/scummvm.ini <<INI
[scummvm]
savepath=$WORK/saves
vsync=false
album_touch_snap=20
album_remote=true
INI

echo "== Sauvegardes (copiées depuis le projet : courant = partie terminée, album 5 ; autres = points de reprise)"
for d in $PROJ/sauvegardes/*(/); do [ -d $WORK/saves_backup_${d:t} ] || cp -R $d $WORK/saves_backup_${d:t}; done
[ -n "$(ls $WORK/saves 2>/dev/null)" ] || cp -R $PROJ/sauvegardes/courant/. $WORK/saves/

echo "== Scripts de pilotage"
cp $PROJ/tools/*.sh $PROJ/tools/*.py $WORK/ && chmod +x $WORK/*.sh
echo "OK. Lancer : $WORK/to_album.sh   (va jusqu'à l'album en ~3 min 30)"
