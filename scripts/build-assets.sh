#!/usr/bin/env bash
# Stiahne fotky (Higgsfield, Unsplash) a video a zmenší ich pre web.
set -euo pipefail
OUT="${1:-_site}"
mkdir -p "$OUT/img" tmp
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
    photo-hero)
      # statická snímka z videa (6,2 s): pani drží psíkovi bradu otvorenou dlaňou
      ffmpeg -nostdin -loglevel error -y -ss 6.2 -i "$src" -frames:v 1 tmp/poster.png
      cwebp -quiet -q 85 -resize 1600 0 tmp/poster.png -o "$OUT/img/hero.webp"
      ffmpeg -nostdin -loglevel error -y -i tmp/poster.png -vf "scale=1200:630:force_original_aspect_ratio=increase,crop=1200:630" -q:v 3 "$OUT/img/og.jpg" ;;
    *)
      cwebp -quiet -q 78 -resize 1000 0 "$src" -o "$OUT/img/$name.webp" ;;
  esac
done
ls -la "$OUT/img"
