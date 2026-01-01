#!/bin/bash
# Downsize the orthophoto by 50% for better web performance

set -e

cd /workspaces/drone-maps

INPUT="all/odm_orthophoto/odm_orthophoto.tif"
OUTPUT="all/odm_orthophoto/odm_orthophoto_web.tif"
BACKUP="all/odm_orthophoto/odm_orthophoto_web_backup.tif"

echo "==========================================="
echo "Downsizing Orthophoto by 50%"
echo "==========================================="
echo ""

# Check if GDAL is installed
if ! command -v gdal_translate &> /dev/null; then
    echo "ERROR: gdal_translate not found!"
    echo ""
    echo "Installing GDAL..."
    sudo apt-get update && sudo apt-get install -y gdal-bin
fi

# Backup existing web version if it exists
if [ -f "$OUTPUT" ]; then
    echo "Backing up existing web version..."
    cp "$OUTPUT" "$BACKUP"
    echo "Backup created: $BACKUP"
fi

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "ERROR: Input file not found: $INPUT"
    exit 1
fi

# Get original file size
ORIGINAL_SIZE=$(du -h "$INPUT" | cut -f1)
echo "Original file size: $ORIGINAL_SIZE"
echo ""

# Downsize by 50% (which results in 25% file size)
echo "Processing... (this may take a few minutes)"
gdal_translate \
    -outsize 50% 50% \
    -co COMPRESS=JPEG \
    -co JPEG_QUALITY=85 \
    -co TILED=YES \
    -co BIGTIFF=IF_SAFER \
    "$INPUT" \
    "$OUTPUT"

echo ""
echo "✓ Done!"
echo ""

# Show file sizes
NEW_SIZE=$(du -h "$OUTPUT" | cut -f1)
echo "Original file: $ORIGINAL_SIZE"
echo "New web file: $NEW_SIZE"
echo ""
echo "==========================================="
echo "The downsized file is ready at:"
echo "  $OUTPUT"
echo ""
echo "Refresh your browser to see the changes."
echo "==========================================="
