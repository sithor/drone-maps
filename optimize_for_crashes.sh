#!/bin/bash
# Enhanced optimization script with crash prevention

echo "==========================================="
echo "Drone Maps Crash Prevention & Optimization"
echo "==========================================="
echo ""

# Function to check available memory
check_memory() {
    if command -v free &> /dev/null; then
        available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        echo "Available memory: ${available_mem}MB"
        
        if [ "$available_mem" -lt 1000 ]; then
            echo "⚠️  Low memory detected (${available_mem}MB)"
            echo "   This may cause crashes with large files"
            echo "   Consider using smaller scaling factors"
            echo ""
        fi
    fi
}

# Function to kill any hanging processes
cleanup_processes() {
    echo "Cleaning up any hanging processes..."
    
    # Try to kill any python http servers (ignore errors)
    pgrep -f "python.*http.server" > /dev/null 2>&1 && pkill -f "python.*http.server" 2>/dev/null || true
    pgrep -f "python.*-m.*http.server" > /dev/null 2>&1 && pkill -f "python.*-m.*http.server" 2>/dev/null || true
    
    # Try to kill any node processes (ignore errors)
    pgrep -f "node.*serve" > /dev/null 2>&1 && pkill -f "node.*serve" 2>/dev/null || true
    
    echo "✓ Process cleanup completed"
    echo ""
}

# Function to optimize file for web
optimize_for_web() {
    local input_file="$1"
    local output_file="$2"
    local scale="${3:-0.5}"
    
    if [ ! -f "$input_file" ]; then
        echo "❌ Input file not found: $input_file"
        return 1
    fi
    
    # Check input file size
    input_size=$(stat -c%s "$input_file" 2>/dev/null || stat -f%z "$input_file" 2>/dev/null || echo "0")
    input_size_mb=$((input_size / 1024 / 1024))
    
    echo "Input file size: ${input_size_mb}MB"
    
    if [ "$input_size_mb" -gt 500 ]; then
        echo "⚠️  Very large input file detected"
        echo "   Reducing scale factor to prevent crashes"
        # Simple calculation without bc
        scale="0.25"
    fi
    
    echo "Using scale factor: $scale"
    
    # Calculate percentage (simple integer math)
    scale_percent=$(printf "%.0f" $(echo "$scale * 100" | awk '{print $1 * $3}'))
    
    # Create optimized version
    gdal_translate \
        -outsize ${scale_percent}% 0 \
        -co "COMPRESS=JPEG" \
        -co "TILED=YES" \
        -co "BLOCKXSIZE=512" \
        -co "BLOCKYSIZE=512" \
        -co "JPEG_QUALITY=85" \
        "$input_file" \
        "$output_file"
    
    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        output_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null || echo "0")
        output_size_mb=$((output_size / 1024 / 1024))
        reduction=$((100 - (output_size * 100 / input_size)))
        
        echo "✅ Optimization successful!"
        echo "   Output size: ${output_size_mb}MB"
        echo "   Size reduction: ${reduction}%"
        
        # Warn if still too large
        if [ "$output_size_mb" -gt 100 ]; then
            echo "⚠️  Output file is still large (${output_size_mb}MB)"
            echo "   Consider running with smaller scale:"
            echo "   ./optimize_for_crashes.sh 0.3"
        fi
        
        return 0
    else
        echo "❌ Optimization failed"
        return 1
    fi
}

# Main execution
echo "Step 1: System checks"
check_memory

echo "Step 2: Check GDAL installation"
if ! command -v gdal_translate &> /dev/null; then
    echo "GDAL not found. Installing..."
    if [ "$EUID" -ne 0 ]; then
        sudo apt-get update && sudo apt-get install -y gdal-bin
    else
        apt-get update && apt-get install -y gdal-bin
    fi
fi

if ! command -v gdal_translate &> /dev/null; then
    echo "❌ Failed to install GDAL"
    exit 1
fi

echo "✓ GDAL is available"
echo ""

echo "Step 3: File optimization"
cd "$(dirname "$0")"

# Set scale factor (default 0.5, or from command line)
SCALE=${1:-0.5}
echo "Using scale factor: $SCALE"

# Define file paths
INPUT_FILE="all/odm_orthophoto/odm_orthophoto.tif"
OUTPUT_FILE="all/odm_orthophoto/odm_orthophoto_web.tif"
BACKUP_FILE="all/odm_orthophoto/odm_orthophoto_original.tif"

# Check if original exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Original orthophoto not found: $INPUT_FILE"
    echo "   Make sure your ODM processing completed successfully"
    exit 1
fi

# Create backup if it doesn't exist
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Creating backup of original file..."
    cp "$INPUT_FILE" "$BACKUP_FILE"
    echo "✓ Backup created: $BACKUP_FILE"
fi

# Remove old web version if exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Removing old web version..."
    rm -f "$OUTPUT_FILE"
fi

# Optimize the file
echo "Optimizing orthophoto for web..."
if optimize_for_web "$INPUT_FILE" "$OUTPUT_FILE" "$SCALE"; then
    echo ""
    echo "🎉 SUCCESS! Web-optimized orthophoto created."
    echo ""
    echo "Files created:"
    echo "  📄 $OUTPUT_FILE (web version)"
    echo "  💾 $BACKUP_FILE (backup)"
    echo ""
    echo "Next steps:"
    echo "1. Start your web server:"
    echo "   python3 -m http.server 3004"
    echo ""
    echo "2. Open your browser to:"
    echo "   http://localhost:3004"
    echo ""
    echo "The application should now load much faster! 🚀"
else
    echo ""
    echo "❌ Optimization failed"
    echo ""
    echo "Troubleshooting:"
    echo "1. Try with a smaller scale: ./optimize_for_crashes.sh 0.3"
    echo "2. Check available disk space"
    echo "3. Ensure you have write permissions"
    exit 1
fi