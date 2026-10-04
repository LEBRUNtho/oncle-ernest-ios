#!/bin/zsh
# Construit l'application iPhone « L'Île Mystérieuse » (jeu 3) : ScummVM patché (moteur mTropolis seul) + données du jeu embarquées.
# Usage : tools/build-ios.sh [ipa|install]
#   (défaut)  compile + paquet signé dans $WORK/build-ios/AlbumErnest.app
#   ipa       + releases/VoyageErnest-iOS.ipa (à installer avec Feather)
#   install   + installation directe sur l'iPhone branché (devicectl)
# Prérequis : tools/setup.sh déjà passé (dossier de travail $WORK avec scummvm/ et data/)
set -e
# Signature personnelle (facultative) : ~/.config/oncle-ernest/signature.sh définit SIGN_IDENTITY, SIGN_TEAM,
# SIGN_PROFILE et BUNDLE_PREFIX. Sans ce fichier, l'app est construite NON signée (à signer avec son propre outil
# de sideloading : Feather, AltStore, Sideloadly...).
[ -f "$HOME/.config/oncle-ernest/signature.sh" ] && source "$HOME/.config/oncle-ernest/signature.sh"
BUNDLE_PREFIX=${BUNDLE_PREFIX:-com.example}
PROJ=${0:A:h:h}
WORK=${WORK:-$HOME/album-ernest-build}   # moteur ScummVM COMMUN aux deux jeux (même patch)
GAME3=${GAME3:-$HOME/album3-build}
MODE=${1:-app}
BUNDLE_ID="${BUNDLE_PREFIX}.ileernest"
APPNAME="IleErnest"
DISPLAY="L'Île"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
T=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
B=$WORK/build-ios
mkdir -p $B && cd $B

if [ ! -f config.mk ]; then
  echo "== Configuration iOS (arm64, mTropolis seul, sans bibliothèques externes)"
  CC="$T/clang -isysroot $SDK" CXX="$T/clang++ -isysroot $SDK" AR="$T/ar" RANLIB="$T/ranlib" STRIP="$T/strip" \
  ../scummvm/configure --host=ios7-arm64 --backend=ios7 --disable-all-engines --enable-engine=mtropolis \
    --disable-debug --enable-release --enable-static \
    --disable-mt32emu --disable-png --disable-jpeg --disable-freetype2 --disable-vorbis --disable-tremor --disable-flac \
    --disable-mad --disable-faad --disable-fluidsynth --disable-libcurl --disable-sdlnet --disable-theoradec --disable-vpx \
    --disable-gif --disable-fribidi --disable-readline --disable-tts --disable-cloud --disable-libunity --disable-discord \
    --disable-sparkle --disable-lua --disable-nasm --disable-opengl-game --disable-opengl-game-shaders > /tmp/ios_cfg.log
  # iOS 7.1 par défaut : trop ancien pour la libc++ actuelle
  sed -i '' 's/-miphoneos-version-min=7.1/-miphoneos-version-min=15.0/g' config.mk
fi

echo "== Compilation"
# iPhone : maintien en vie en arrière-plan (silence joué, AVAudioSession) → AVFoundation
grep -q 'framework AVFoundation' config.mk || sed -i '' 's/-framework AudioToolbox/-framework AVFoundation -framework AudioToolbox/' config.mk
make -j$(sysctl -n hw.ncpu) > /tmp/ios_build.log 2>&1 || { grep -E " error" /tmp/ios_build.log | head; exit 1; }
# OSX_STATIC_LIBS vidé : la règle reprend sinon SDL/OpenGL du Mac
make ios7bundle OSX_STATIC_LIBS="" > /tmp/ios_bundle.log 2>&1 || { tail -20 /tmp/ios_bundle.log; exit 1; }

echo "== Paquet $APPNAME.app"
APP=$B/$APPNAME.app
rm -rf $APP && cp -R $B/ScummVM.app $APP
rm -rf $APP/_CodeSignature
# COPYING.MPL (licence Mozilla) a la même extension que le fichier du jeu : on l'écarte de la racine
mkdir -p $APP/licences && mv $APP/COPYING* $APP/licences/ 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" $APP/Info.plist
plutil -replace CFBundleDisplayName -string "$DISPLAY" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APPNAME" $APP/Info.plist
# Le jeu est en paysage
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations" $APP/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations array" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationLandscapeLeft" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations:1 string UIInterfaceOrientationLandscapeRight" $APP/Info.plist
# iPad : paysage aussi, plein écran (sinon iPadOS ouvre l'app en fenêtre / portrait) ; barre d'état masquée
/usr/libexec/PlistBuddy -c "Delete :UISupportedInterfaceOrientations~ipad" $APP/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations~ipad array" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations~ipad:0 string UIInterfaceOrientationLandscapeLeft" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Add :UISupportedInterfaceOrientations~ipad:1 string UIInterfaceOrientationLandscapeRight" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Set :UIRequiresFullScreen true" $APP/Info.plist 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :UIRequiresFullScreen bool true" $APP/Info.plist
# lecteur audio d'arrière-plan : iOS ne ferme plus l'app quand on en sort (reprise instantanée)
/usr/libexec/PlistBuddy -c "Delete :UIBackgroundModes" $APP/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string audio" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Delete :UIStatusBarHidden" $APP/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIStatusBarHidden bool true" $APP/Info.plist
/usr/libexec/PlistBuddy -c "Delete :UIViewControllerBasedStatusBarAppearance" $APP/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIViewControllerBasedStatusBarAppearance bool false" $APP/Info.plist
# Écran de démarrage noir moderne (storyboard) au lieu des vieilles images ScummVM : sans ça, iOS lance l'app en mode
# compatibilité iPhone 5 (568×320 points agrandis) → clavier énorme, texte flou, logo ScummVM au démarrage
cp -R $PROJ/tools/launch/LaunchScreen.storyboardc $APP/
rm -f $APP/LaunchImage*.png
for key in UILaunchImages UILaunchImages~ipad UILaunchImages~iphone UILaunchImageFile UILaunchImageFile~ipad UILaunchStoryboardName; do
  /usr/libexec/PlistBuddy -c "Delete :$key" $APP/Info.plist 2>/dev/null || true
done
/usr/libexec/PlistBuddy -c "Add :UILaunchStoryboardName string LaunchScreen" $APP/Info.plist
# Sauvegardes visibles dans l'app Fichiers (Sur mon iPhone > Album d'Ernest > Savegames) : copie / transfert iPhone ↔ iPad
for key in UIFileSharingEnabled LSSupportsOpeningDocumentsInPlace; do
  /usr/libexec/PlistBuddy -c "Delete :$key" $APP/Info.plist 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :$key bool true" $APP/Info.plist
done

# Données du jeu : le dossier « game » du paquet est détecté et lancé directement par ScummVM iOS
mkdir -p $APP/game
# jeu 3 : dossier à plat préparé par tools/setup.sh (liens suivis)
cp -RL $GAME3/game/ $APP/game/
# Sonde Album : icônes des boutons des bandes latérales (HD du mainteneur ou extraites du jeu)
rm -rf $APP/album_icons; ditto $PROJ/tools/album_icons $APP/album_icons
# Configuration initiale
cp $PROJ/tools/scummvm-ios.ini $APP/scummvm.ini 2>/dev/null || true

# Icône (si fournie)
if [ -d $PROJ/tools/icon ]; then cp $PROJ/tools/icon/AppIcon*.png $APP/ 2>/dev/null || true; fi

echo "== Signature"
if [ -n "$SIGN_IDENTITY" ]; then
  security find-identity -v -p codesigning | grep -q "$SIGN_IDENTITY" || { echo "!! certificat absent du trousseau"; exit 1; }
  cp "$SIGN_PROFILE" $APP/embedded.mobileprovision
  cat > $B/ent.plist <<EOP
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>application-identifier</key><string>$SIGN_TEAM.$BUNDLE_ID</string>
  <key>com.apple.developer.team-identifier</key><string>$SIGN_TEAM</string>
  <key>get-task-allow</key><true/>
</dict></plist>
EOP
  codesign --force --sign "$SIGN_IDENTITY" --timestamp=none --entitlements $B/ent.plist $APP
else
  echo "   (pas de signature personnelle : app non signée, à signer avec un outil de sideloading)"
  rm -f $APP/embedded.mobileprovision
  codesign --force --sign - --timestamp=none $APP
fi
codesign --verify --verbose=1 $APP
echo "== App prête : $APP ($(du -sh $APP | cut -f1))"

if [ "$MODE" = ipa ] || [ "$MODE" = install ]; then
  STAGE=$(mktemp -d); mkdir -p $STAGE/Payload
  ditto --norsrc --noextattr $APP $STAGE/Payload/$APPNAME.app
  IPA=$PROJ/releases/$APPNAME-iOS.ipa; mkdir -p $PROJ/releases; rm -f $IPA
  (cd $STAGE && zip -qry -X $IPA Payload); rm -rf $STAGE
  echo "== IPA : $IPA ($(du -h $IPA | cut -f1))"
fi

if [ "$MODE" = install ]; then
  DEV=$(xcrun devicectl list devices 2>/dev/null | awk '/connected/ {print $3; exit}')
  [ -n "$DEV" ] || { echo "!! aucun iPhone branché/déverrouillé"; exit 1; }
  xcrun devicectl device install app --device $DEV $APP
fi
