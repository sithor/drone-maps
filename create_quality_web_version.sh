#!/bin/bash
# Create a high-quality web version (150-200MB) to avoid blockiness

set -e

cd /workspaces/drone-maps

INPUT="all/odm_orthophoto/odm_orthophoto_original.tif"
OUTPUT="all/odm_orthophoto/odm_orthophoto_web.tif"
BACKUP="all/odm_orthophoto/odm_orthophoto_web_backup_$(date +%Y%m%d_%H%M%S).tif"

echo "==========================================="
echo "Creating High-Quality Web Orthophoto"
echo "==========================================="
echo ""

# Backup existing web version
if [ -f "$OUTPUT" ]; then
    echo "Backing up existing version..."
    cp "$OUTPUT" "$BACKUP"
fi

echo "Original file: $INPUT"
du -h "$INPUT" | cut -f1 | xargs -I {} echo "Original size: {}"
echo ""

# Use 70% scale with maximum quality to avoid blockiness
# 70% dimensions = ~49% file size, so 331MB * 0.49 = ~162MB
SCALE=70

echo "Using scale: ${SCALE}% of original dimensions"
echo "Target size: ~150-200MB for high quality"
echo ""
echo "Processing with maximum quality settings..."
echo "(This may take 3-5 minutes)"
echo ""

# Maximum quality settings:
# - JPEG_QUALITY=95 (very high quality)
# - lanczos resampling (best quality)
# - TILED=YES for better performance
gdal_translate \
    -outsize ${SCALE}% ${SCALE}% \
    -co COMPRESS=JPEG \
    -co JPEG_QUALITY=95 \
    -co TILED=YES \
    -co BIGTIFF=IF_SAFER \
    -r lanczos \
    "$INPUT" \
    "$OUTPUT"

echo ""
echo "✓ Done!"
echo ""

# Show results
du -h "$INPUT" | cut -f1 | xargs -I {} echo "  Original:  {}"
du -h "$OUTPUT" | cut -f1 | xargs -I {} echo "  Web file:  {}"
echo ""
echo "==========================================="
echo "High-quality web version created!"
echo ""
echo "Do a HARD REFRESH in your browser:"
echo "  Chrome/Firefox: Ctrl+Shift+R"
echo "  Mac: Cmd+Shift+R"
echo "==========================================="
