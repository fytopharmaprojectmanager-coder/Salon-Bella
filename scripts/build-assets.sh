#!/usr/bin/env bash
# Stiahne fotky (Higgsfield, Unsplash) a video a zmenší ich pre web.
set -euo pipefail
OUT="${1:-_site}"
mkdir -p "$OUT/img" "$OUT/video" tmp
grep -v '^#' assets.txt | grep -v '^\s*$' | while read -r name url; do
  curl -fsSL --retry 3 -o "tmp/$name.dl" "$url"
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
      ffmpeg -nostdin -loglevel error -y -i "$src" -an -c:v libx264 -preset slow -crf 27 \
        -filter_complex "[0:v]scale=1280:-2,fps=30,split[a][b];[b]reverse[r];[a][r]concat=n=2:v=1:a=0" -pix_fmt yuv420p -movflags +faststart "$OUT/video/hero.mp4" ;;
    *)
      cwebp -quiet -q 78 -resize 1000 0 "$src" -o "$OUT/img/$name.webp" ;;
  esac
done
ls -la "$OUT/img" "$OUT/video"
