#!/usr/bin/env bash
# Stiahne fotky (Higgsfield, Unsplash) a video a zmenší ich pre web.
set -euo pipefail
# Jemná teplá farebnosť úvodného videa (ružové pozadie -> béžové)
GRADE="hue=s=0.12,colorchannelmixer=rr=1.063:rg=0.300:rb=0.074:gr=0.137:gg=1.178:gb=0.065:br=0.107:bg=0.208:bb=0.961,eq=contrast=0.86"
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
      ffmpeg -nostdin -loglevel error -y -ss 0.3 -t 20 -i "$src" -an -c:v libx264 -preset slow -crf 28 \
        -vf "scale=1280:-2,fps=30,$GRADE" -pix_fmt yuv420p -movflags +faststart "$OUT/video/hero.mp4"
      ffmpeg -nostdin -loglevel error -y -ss 1.3 -i "$src" -frames:v 1 -vf "$GRADE" tmp/poster.png
      cwebp -quiet -q 80 -resize 1280 0 tmp/poster.png -o "$OUT/img/hero.webp"
      ffmpeg -nostdin -loglevel error -y -i tmp/poster.png -vf "scale=1200:630:force_original_aspect_ratio=increase,crop=1200:630" -q:v 4 "$OUT/img/og.jpg" ;;
    *)
      cwebp -quiet -q 78 -resize 1000 0 "$src" -o "$OUT/img/$name.webp" ;;
  esac
done
ls -la "$OUT/img" "$OUT/video"
