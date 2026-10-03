#!/bin/zsh
# Jeu 4 : les cinématiques C1..C5 sont en Sorenson Video 3 (non lu par ScummVM) -> Sorenson Video 1, même nom, son réencodé en ADPCM ima4 (la simple copie par ffmpeg coupait la lecture vers 23 s dans ScummVM).
# Originaux gardés dans ~/album4-build/original/videos_svq3/. Usage : convert_videos.sh [dossier Assets]
set -e
FF=~/album4-build/venvff/lib/python3.12/site-packages/imageio_ffmpeg/binaries/ffmpeg-macos-aarch64-v7.1
A=${1:-$HOME/album4-build/game/Assets}
for f in $A/C?_Sorenson.mov; do
  b=${f:t}; o=~/album4-build/original/videos_svq3/$b
  [ -f $o ] || cp $f $o
  $FF -hide_banner -loglevel error -y -i $o -vf scale=in_range=full:out_range=limited -c:v svq1 -qscale:v 3 -pix_fmt yuv410p -c:a adpcm_ima_qt -f mov /tmp/conv_$b
  mv /tmp/conv_$b $f
  echo "$b : $(du -h $o | cut -f1) -> $(du -h $f | cut -f1)"
done
