#!/bin/bash
# Downsize DEM for web viewing using gdal_translate

INPUT="all/odm_dem/dsm.tif"
OUTPUT="all/odm_dem/dsm_web.tif"

echo "========================================"
echo "DEM Web Optimizer for Drone Mapping"
echo "========================================"

if [ ! -f "$INPUT" ]; then
    echo "❌ Error: Input DEM not found: $INPUT"
    exit 1
fi

# Get original file size
ORIGINAL_SIZE=$(du -h "$INPUT" | cut -f1)
echo "Original DEM: $ORIGINAL_SIZE"

# Downsize and reproject to WGS84 lat/lng for web use
echo "Processing... (this may take a minute)"
echo "Step 1: Reprojecting to WGS84..."
gdalwarp \
    -t_srs EPSG:4326 \
    -r cubic \
    -tr 0.00001 0.00001 \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=2 \
    -co ZLEVEL=9 \
    -co TILED=YES \
    "$INPUT" "$OUTPUT"

if [ $? -ne 0 ]; then
    echo "Reprojection failed, trying with gdal_translate only..."
    gdal_translate \
        -of GTiff \
        -outsize 20% 20% \
        -r cubic \
        -co COMPRESS=DEFLATE \
        -co PREDICTOR=2 \
        -co ZLEVEL=9 \
        -co TILED=YES \
        "$INPUT" "$OUTPUT"
fi

if [ -f "$OUTPUT" ]; then
    OUTPUT_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "========================================"
    echo "✅ SUCCESS!"
    echo "========================================"
    echo "Created: $OUTPUT"
    echo "Size: $OUTPUT_SIZE"
    echo ""
    echo "Your measurement tools will now work with 3D terrain data!"
    echo "Refresh your browser to load the new DEM."
else
    echo "❌ Failed to create output file"
    exit 1
fi
