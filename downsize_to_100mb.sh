#!/bin/bash
# Downsize the orthophoto to approximately 100MB with high quality

set -e

cd /workspaces/drone-maps

INPUT="all/odm_orthophoto/odm_orthophoto_original.tif"
OUTPUT="all/odm_orthophoto/odm_orthophoto_web.tif"
BACKUP="all/odm_orthophoto/odm_orthophoto_web_backup_$(date +%Y%m%d_%H%M%S).tif"
TARGET_MB=100

echo "==========================================="
echo "Downsizing Orthophoto to ~${TARGET_MB}MB"
echo "==========================================="
echo ""

# Check if GDAL is installed
if ! command -v gdal_translate &> /dev/null; then
    echo "ERROR: gdal_translate not found!"
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
    echo "Trying alternative input..."
    INPUT="all/odm_orthophoto/odm_orthophoto.tif"
    if [ ! -f "$INPUT" ]; then
        echo "ERROR: No input file found!"
        exit 1
    fi
fi

echo "Original file: $INPUT"
du -h "$INPUT" | cut -f1 | xargs -I {} echo "Original size: {}"
echo ""

# Use Python to calculate the scale percentage
SCALE_PERCENT=$(python3 << 'EOF'
import os
import math

input_file = "all/odm_orthophoto/odm_orthophoto_original.tif"
if not os.path.exists(input_file):
    input_file = "all/odm_orthophoto/odm_orthophoto.tif"

original_size_mb = os.path.getsize(input_file) / (1024 * 1024)
target_mb = 100

# Calculate scale factor (sqrt because area scales with scale^2)
scale_factor = math.sqrt(target_mb / original_size_mb)
scale_percent = min(scale_factor * 100, 100)  # Cap at 100%

print(f"{scale_percent:.1f}")
EOF
)

echo "Calculated scale: ${SCALE_PERCENT}% of original dimensions"
echo "This should result in approximately ${TARGET_MB}MB"
echo ""
echo "Processing... (this may take several minutes)"
echo ""

# Downsize with high quality settings to avoid blockiness
gdal_translate \
    -outsize ${SCALE_PERCENT}% ${SCALE_PERCENT}% \
    -co COMPRESS=JPEG \
    -co JPEG_QUALITY=92 \
    -co TILED=YES \
    -co BIGTIFF=IF_SAFER \
    -r lanczos \
    "$INPUT" \
    "$OUTPUT"

echo ""
echo "✓ Done!"
echo ""

# Show file sizes
du -h "$INPUT" | cut -f1 | xargs -I {} echo "  Original:  {}"
du -h "$OUTPUT" | cut -f1 | xargs -I {} echo "  New file:  {}"
echo ""
echo "==========================================="
echo "The high-quality downsized file is ready!"
echo ""
echo "Refresh your browser to see the changes."
echo "==========================================="
