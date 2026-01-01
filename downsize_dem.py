#!/usr/bin/env python3
"""
Downsize DEM (Digital Elevation Model) for web viewing
Creates a smaller, web-optimized version of the DSM
"""

import os
import sys
from osgeo import gdal
import numpy as np

def downsize_dem(input_path, output_path, target_size_mb=10):
    """
    Downsize a DEM file to a target size for web viewing
    """
    print(f"Loading DEM from: {input_path}")
    
    # Open the input DEM
    ds = gdal.Open(input_path)
    if ds is None:
        print(f"ERROR: Could not open {input_path}")
        return False
    
    # Get original dimensions
    width = ds.RasterXSize
    height = ds.RasterYSize
    band = ds.GetRasterBand(1)
    
    print(f"Original DEM size: {width}x{height} pixels")
    
    # Calculate current file size
    current_size_mb = os.path.getsize(input_path) / (1024 * 1024)
    print(f"Current file size: {current_size_mb:.1f} MB")
    
    if current_size_mb <= target_size_mb:
        print(f"DEM is already under {target_size_mb} MB, no need to downsize")
        return True
    
    # Calculate scale factor to reach target size
    # Size scales roughly with (width * height)
    scale_factor = np.sqrt(target_size_mb / current_size_mb)
    new_width = int(width * scale_factor)
    new_height = int(height * scale_factor)
    
    print(f"Downsampling to: {new_width}x{new_height} pixels (scale: {scale_factor:.2f})")
    
    # Create output with GDAL translate
    translate_options = gdal.TranslateOptions(
        format='GTiff',
        width=new_width,
        height=new_height,
        resampleAlg='bilinear',  # Good balance for elevation data
        creationOptions=[
            'TILED=YES',
            'COMPRESS=DEFLATE',
            'PREDICTOR=2',
            'ZLEVEL=9'
        ]
    )
    
    print("Processing... (this may take a minute)")
    gdal.Translate(output_path, ds, options=translate_options)
    
    # Verify output
    if os.path.exists(output_path):
        output_size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"✅ Created web-optimized DEM: {output_path}")
        print(f"   Output size: {output_size_mb:.1f} MB")
        print(f"   Compression ratio: {current_size_mb/output_size_mb:.1f}x")
        return True
    else:
        print("❌ Failed to create output file")
        return False

def main():
    input_dem = "all/odm_dem/dsm.tif"
    output_dem = "all/odm_dem/dsm_web.tif"
    
    if not os.path.exists(input_dem):
        print(f"ERROR: Input DEM not found: {input_dem}")
        print("Make sure you have run WebODM/ODM processing first")
        return 1
    
    print("=" * 60)
    print("DEM Web Optimizer for Drone Mapping")
    print("=" * 60)
    
    success = downsize_dem(input_dem, output_dem, target_size_mb=10)
    
    if success:
        print("\n" + "=" * 60)
        print("✅ SUCCESS!")
        print("=" * 60)
        print(f"Web-optimized DEM created: {output_dem}")
        print("\nYour measurement tools will now work with 3D terrain data!")
        return 0
    else:
        print("\n❌ Failed to create web DEM")
        return 1

if __name__ == "__main__":
    sys.exit(main())
