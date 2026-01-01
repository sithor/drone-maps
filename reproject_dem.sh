


#!/bin/bash
# Reproject DEM from UTM to WGS84 lat/lng

INPUT="all/odm_dem/dsm.tif"
OUTPUT="all/odm_dem/dsm_web.tif"

echo "========================================"
echo "Reprojecting DEM to WGS84"
echo "========================================"

# Remove old file if it exists
if [ -f "$OUTPUT" ]; then
    echo "Removing old dsm_web.tif..."
    rm "$OUTPUT"
fi

# Check input
if [ ! -f "$INPUT" ]; then
    echo "❌ Error: $INPUT not found"
    exit 1
fi

echo "Input: $INPUT"
echo "Output: $OUTPUT"
echo ""
echo "Reprojecting from UTM Zone 60S to WGS84 with high resolution..."

# Reproject with high resolution: 0.000005 degrees ≈ 0.5m resolution
# Maximum terrain detail for accurate 3D measurements
gdalwarp \
    -s_srs EPSG:32760 \
    -t_srs EPSG:4326 \
    -r cubic \
    -tr 0.000005 0.000005 \
    -dstnodata -9999 \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=2 \
    -co ZLEVEL=9 \
    -co TILED=YES \
    "$INPUT" "$OUTPUT"

if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo ""
    echo "========================================"
    echo "✅ SUCCESS!"
    echo "========================================"
    echo "Created: $OUTPUT ($SIZE)"
    echo ""
    echo "Verifying coordinates..."
    gdalinfo "$OUTPUT" | grep -A 5 "Corner Coordinates"
    echo ""
    echo "Refresh your browser to use 3D measurements!"
else
    echo ""
    echo "❌ Failed to reproject DEM"
    exit 1
fi
