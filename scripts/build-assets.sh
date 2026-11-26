#!/usr/bin/env bash
# Stiahne fotky a video z Higgsfieldu a zmenší ich pre web.
set -euo pipefail
OUT="${1:-_site}"
mkdir -p "$OUT/img" "$OUT/video" tmp
grep -v '^#' assets.txt | grep -v '^\s*$' | while read -r name url; do
  ext="${url##*.}"
  curl -fsSL --retry 3 -o "tmp/$name.$ext" "$url"
  case "$name" in
    hero)
      cwebp -quiet -q 80 -resize 1800 0 "tmp/$name.$ext" -o "$OUT/img/hero.webp"
      ffmpeg -loglevel error -y -i "tmp/$name.$ext" -vf "scale=1200:630:force_original_aspect_ratio=increase,crop=1200:630" -q:v 4 "$OUT/img/og.jpg" ;;
    video-hero)
      ffmpeg -loglevel error -y -i "tmp/$name.$ext" -an -c:v libx264 -preset slow -crf 27 \
        -vf "scale=1280:-2,fps=30" -pix_fmt yuv420p -movflags +faststart "$OUT/video/hero.mp4" ;;
    *)
      cwebp -quiet -q 78 -resize 1000 0 "tmp/$name.$ext" -o "$OUT/img/$name.webp" ;;
  esac
done
ls -la "$OUT/img" "$OUT/video"
