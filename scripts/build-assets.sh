#!/usr/bin/env bash
# Stiahne fotky (Higgsfield, Unsplash) a video a zmenší ich pre web.
set -euo pipefail
OUT="${1:-_site}"
mkdir -p "$OUT/img" "$OUT/video" tmp
grep -v '^#' assets.txt | grep -v '^\s*$' | while read -r name url; do
  curl -fsSL --retry 3 -A "Mozilla/5.0" -e "https://www.pexels.com/" -o "tmp/$name.dl" "$url"
  case "$(file -b --mime-type "tmp/$name.dl")" in
    image/jpeg) mv "tmp/$name.dl" "tmp/$name.jpg"; src="tmp/$name.jpg" ;;
    image/png)  mv "tmp/$name.dl" "tmp/$name.png"; src="tmp/$name.png" ;;
    image/webp) mv "tmp/$name.dl" "tmp/$name.webp"; src="tmp/$name.webp" ;;
    *)          mv "tmp/$name.dl" "tmp/$name.mp4"; src="tmp/$name.mp4" ;;
  esac
  case "$name" in
    hero)
      cwebp -quiet -q 80 -resize 1800 0 "$src" -o "$OUT/img/hero.webp"
      ffmpeg -nostdin -loglevel error -y -i "$src" -vf "scale=1200:630:force_original_aspect_ratio=increase,crop=1200:630" -q:v 4 "$OUT/img/og.jpg" ;;
    video-hero)
      # spomaliť na 80 % a koniec plynule prelínať do začiatku (bezšvová slučka)
      D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$src")
      read F OFF <<<"$(awk -v d="$D" 'BEGIN{s=1.25; F=1.25; printf "%.3f %.3f", F, d*s-F-F}')"
      ffmpeg -nostdin -loglevel error -y -i "$src" -an -filter_complex \
        "[0:v]setpts=1.25*PTS,scale=1280:-2,fps=30,format=yuv420p,split[x][y];[x]trim=start=$F,setpts=PTS-STARTPTS[a];[y]trim=end=$F,setpts=PTS-STARTPTS[b];[a][b]xfade=transition=fade:duration=$F:offset=$OFF[v]" \
        -map "[v]" -c:v libx264 -preset slow -crf 27 -pix_fmt yuv420p -movflags +faststart "$OUT/video/hero.mp4"
      ffmpeg -nostdin -loglevel error -y -ss 0.2 -i "$OUT/video/hero.mp4" -frames:v 1 tmp/poster.png
      cwebp -quiet -q 80 -resize 1280 0 tmp/poster.png -o "$OUT/img/hero.webp"
      ffmpeg -nostdin -loglevel error -y -i tmp/poster.png -vf "scale=1200:630:force_original_aspect_ratio=increase,crop=1200:630" -q:v 4 "$OUT/img/og.jpg" ;;
    *)
      cwebp -quiet -q 78 -resize 1000 0 "$src" -o "$OUT/img/$name.webp" ;;
  esac
done
ls -la "$OUT/img" "$OUT/video"
