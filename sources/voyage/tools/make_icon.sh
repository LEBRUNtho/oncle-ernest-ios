#!/bin/zsh
# Fabrique toutes les tailles d'icône iPhone/iPad (tools/icon) à partir d'une image carrée 1024 : make_icon.sh image.png
P=${0:A:h}/icon; SRC=${1:A}; mkdir -p $P; cp "$SRC" $P/icon_1024.png
for spec in "29x29@2x 58" "29x29@3x 87" "29x29~ipad 29" "29x29@2x~ipad 58" "29x29@3x~ipad 87" "40x40@2x 80" "40x40@3x 120" \
            "40x40~ipad 40" "40x40@2x~ipad 80" "40x40@3x~ipad 120" "60x60@2x 120" "60x60@3x 180" "76x76~ipad 76" \
            "76x76@2x~ipad 152" "83.5x83.5@2x~ipad 167"; do
  n=${spec% *}; s=${spec#* }; sips -s format png -z $s $s $P/icon_1024.png --out "$P/AppIcon$n.png" >/dev/null
done
ls $P | wc -l
