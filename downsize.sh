#!/bin/bash
# Quick script to downsize the orthophoto for web use

set -e

INPUT="all/odm_orthophoto/odm_orthophoto.tif"
OUTPUT="all/odm_orthophoto/odm_orthophoto_web.tif"
SCALE="${1:-50}"  # Default to 50% if no argument provided

echo "==========================================="
echo "Orthophoto Downsizing Tool"
echo "==========================================="
echo "Input: $INPUT"
echo "Output: $OUTPUT"
echo "Scale: ${SCALE}%"
echo ""

# Check if GDAL is installed
if ! command -v gdal_translate &> /dev/null; then
    echo "ERROR: gdal_translate not found!"
    echo ""
    echo "Please install GDAL:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install gdal-bin"
    echo ""
    exit 1
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

# Run gdal_translate
echo "Processing..."
gdal_translate \
    -outsize ${SCALE}% ${SCALE}% \
    -co COMPRESS=JPEG \
    -co JPEG_QUALITY=85 \
    -co TILED=YES \
    -co BIGTIFF=IF_SAFER \
    "$INPUT" \
    "$OUTPUT"

# Show results
if [ -f "$OUTPUT" ]; then
    NEW_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo ""
    echo "==========================================="
    echo "✓ Success!"
    echo "==========================================="
    echo "Original size: $ORIGINAL_SIZE"
    echo "New size: $NEW_SIZE"
    echo ""
    echo "The app.js has been updated to use the"
    echo "new file automatically!"
    echo ""
    echo "Restart your web server to see the changes."
else
    echo ""
    echo "ERROR: Output file was not created!"
    exit 1
fi
