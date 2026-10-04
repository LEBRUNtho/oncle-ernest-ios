#!/bin/zsh
# Version simulateur iOS (tests sans iPhone) : compile, embarque le jeu, installe et lance sur le simulateur « iPhone Album Ernest ».
# Usage : tools/build-iossim.sh [run]
set -e
PROJ=${0:A:h:h}
WORK=${WORK:-$HOME/album-ernest-build}   # moteur ScummVM COMMUN aux deux jeux (même patch)
GAME2=${GAME2:-$HOME/album2-build}
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
T=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
B=$WORK/build-iossim; mkdir -p $B && cd $B
if [ ! -f config.mk ]; then
  CC="$T/clang -isysroot $SDK" CXX="$T/clang++ -isysroot $SDK" AR="$T/ar" RANLIB="$T/ranlib" STRIP="$T/strip" \
  ../scummvm/configure --host=ios7-arm64 --backend=ios7 --disable-all-engines --enable-engine=mtropolis --disable-debug --enable-release --enable-static \
    --disable-mt32emu --disable-png --disable-jpeg --disable-freetype2 --disable-vorbis --disable-tremor --disable-flac --disable-mad --disable-faad \
    --disable-fluidsynth --disable-libcurl --disable-sdlnet --disable-theoradec --disable-vpx --disable-gif --disable-fribidi --disable-readline --disable-tts \
    --disable-cloud --disable-libunity --disable-discord --disable-sparkle --disable-lua --disable-nasm --disable-opengl-game --disable-opengl-game-shaders > /tmp/iossim_cfg.log
  sed -i '' 's/-miphoneos-version-min=7.1/-mios-simulator-version-min=15.0/g' config.mk
fi
# iPhone : maintien en vie en arrière-plan (silence joué, AVAudioSession) → AVFoundation
grep -q 'framework AVFoundation' config.mk || sed -i '' 's/-framework AudioToolbox/-framework AVFoundation -framework AudioToolbox/' config.mk
make -j$(sysctl -n hw.ncpu) > /tmp/iossim_build.log 2>&1 || { grep -E " error" /tmp/iossim_build.log | head; exit 1; }
make ios7bundle OSX_STATIC_LIBS="" > /tmp/iossim_bundle.log 2>&1
APP=$B/VoyageErnestSim.app; rm -rf $APP; cp -R ScummVM.app $APP; rm -rf $APP/_CodeSignature
mkdir -p $APP/licences && mv $APP/COPYING* $APP/licences/ 2>/dev/null || true
mkdir -p $APP/game; cp -RL $GAME2/game/ $APP/game/
# Sonde Album : icônes des boutons des bandes latérales (HD du mainteneur ou extraites du jeu)
rm -rf $APP/album_icons; ditto $PROJ/tools/album_icons $APP/album_icons
cp $PROJ/tools/scummvm-ios.ini $APP/scummvm.ini
# Simulateur seulement : télécommande de test active (désactivée dans l'IPA iPhone)
sed -i '' 's/^\[scummvm\]$/[scummvm]\
album_remote=true/' $APP/scummvm.ini
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.example.voyageernest" $APP/Info.plist
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
codesign --force --sign - $APP >/dev/null 2>&1
SIMNAME=${SIMNAME:-iPhone Album Ernest}; SIMTYPE=${SIMTYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro}
UDID=$(xcrun simctl list devices | awk -F'[()]' -v n="$SIMNAME" 'index($0,n" (") {print $2; exit}')
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl create "$SIMNAME" $SIMTYPE com.apple.CoreSimulator.SimRuntime.iOS-26-5)
fi
xcrun simctl boot $UDID 2>/dev/null || true
xcrun simctl uninstall $UDID com.example.voyageernest 2>/dev/null || true
xcrun simctl install $UDID $APP
echo "Simulateur $UDID prêt"
[ "$1" = run ] && xcrun simctl launch $UDID com.example.voyageernest
