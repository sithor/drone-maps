#!/usr/bin/env python3
"""
Script to downsize the orthophoto for faster web loading.
This creates a smaller version of the TIFF file while maintaining quality.
"""

import os
import sys

def check_and_install_gdal():
    """Check if GDAL is available and provide installation instructions if not."""
    try:
        import osgeo.gdal as gdal
        return True
    except ImportError:
        print("GDAL Python bindings not found.")
        print("\nTo install GDAL, run one of these commands:")
        print("  sudo apt-get install gdal-bin python3-gdal")
        print("  or")
        print("  pip install gdal")
        print("\nAlternatively, you can use the command-line tool directly:")
        print("  sudo apt-get install gdal-bin")
        return False

def downsize_with_gdal_command(input_file, output_file, scale=0.5):
    """Downsize using gdal_translate command-line tool."""
    import subprocess
    
    # Check if gdal_translate is available
    try:
        result = subprocess.run(['which', 'gdal_translate'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print("gdal_translate command not found.")
            print("Install with: sudo apt-get install gdal-bin")
            return False
    except Exception as e:
        print(f"Error checking for gdal_translate: {e}")
        return False
    
    # Calculate output dimensions (scale down)
    width_percent = int(scale * 100)
    
    print(f"Downsizing {input_file}...")
    print(f"Scale: {scale} ({width_percent}%)")
    print(f"Output: {output_file}")
    
    # Use gdal_translate to create a smaller version
    # -outsize: specify output size as percentage
    # -co: creation options for compression
    cmd = [
        'gdal_translate',
        '-outsize', f'{width_percent}%', f'{width_percent}%',
        '-co', 'COMPRESS=JPEG',
        '-co', 'JPEG_QUALITY=85',
        '-co', 'TILED=YES',
        '-co', 'BIGTIFF=IF_SAFER',
        input_file,
        output_file
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("\n✓ Downsizing completed successfully!")
        
        # Show file sizes
        input_size = os.path.getsize(input_file) / (1024 * 1024)
        output_size = os.path.getsize(output_file) / (1024 * 1024)
        print(f"\nOriginal size: {input_size:.1f} MB")
        print(f"New size: {output_size:.1f} MB")
        print(f"Reduction: {((input_size - output_size) / input_size * 100):.1f}%")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error during conversion: {e}")
        print(f"stderr: {e.stderr}")
        return False

def main():
    input_file = 'all/odm_orthophoto/odm_orthophoto.tif'
    output_file = 'all/odm_orthophoto/odm_orthophoto_web.tif'
    
    # Default scale factor (0.5 = 50% of original dimensions = 25% of file size)
    # Adjust this value as needed:
    # 0.25 = 25% dimensions (very small, ~6% of original file size)
    # 0.5 = 50% dimensions (medium, ~25% of original file size)
    # 0.75 = 75% dimensions (larger, ~56% of original file size)
    scale = 0.5
    
    if len(sys.argv) > 1:
        try:
            scale = float(sys.argv[1])
            if scale <= 0 or scale > 1:
                print("Scale must be between 0 and 1")
                sys.exit(1)
        except ValueError:
            print("Invalid scale value. Using default: 0.5")
    
    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}")
        sys.exit(1)
    
    print("=" * 60)
    print("Orthophoto Downsizing Tool")
    print("=" * 60)
    
    # Try to use GDAL command-line tool
    if downsize_with_gdal_command(input_file, output_file, scale):
        print("\n" + "=" * 60)
        print("Next steps:")
        print("1. Update app.js to use the new file:")
        print("   Change: 'all/odm_orthophoto/odm_orthophoto.tif'")
        print("   To: 'all/odm_orthophoto/odm_orthophoto_web.tif'")
        print("=" * 60)
    else:
        print("\nFailed to downsize the orthophoto.")
        print("Please ensure GDAL is installed:")
        print("  sudo apt-get update")
        print("  sudo apt-get install gdal-bin")

if __name__ == '__main__':
    main()
