#!/bin/bash
# Setup script to install GDAL and downsize the orthophoto

echo "==========================================="
echo "Orthophoto Optimization Setup"
echo "==========================================="
echo ""

# Check if GDAL is installed
if command -v gdal_translate &> /dev/null; then
    echo "✓ GDAL is already installed"
    gdal_translate --version | head -n 1
else
    echo "GDAL not found. Installing..."
    echo ""
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        echo "This script needs sudo privileges to install GDAL."
        echo "You may be prompted for your password."
        echo ""
        sudo apt-get update
        sudo apt-get install -y gdal-bin
    else
        apt-get update
        apt-get install -y gdal-bin
    fi
    
    if command -v gdal_translate &> /dev/null; then
        echo ""
        echo "✓ GDAL installed successfully!"
    else
        echo ""
        echo "✗ Failed to install GDAL"
        echo "Please install manually: sudo apt-get install gdal-bin"
        exit 1
    fi
fi

echo ""
echo "==========================================="
echo "Starting orthophoto optimization..."
echo "==========================================="
echo ""

# Make downsize.sh executable if it exists
if [ -f "downsize.sh" ]; then
    chmod +x downsize.sh
    ./downsize.sh
else
    echo "ERROR: downsize.sh not found!"
    exit 1
fi
