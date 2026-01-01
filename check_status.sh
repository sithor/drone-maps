#!/bin/bash
# Quick status check for drone maps application

echo "🚁 Drone Maps - System Status"
echo "============================="
echo ""

cd "$(dirname "$0")"

# Check files
echo "📁 File Status:"
if [ -f "all/odm_orthophoto/odm_orthophoto.tif" ]; then
    original_size=$(stat -c%s "all/odm_orthophoto/odm_orthophoto.tif" 2>/dev/null || echo "0")
    original_size_mb=$((original_size / 1024 / 1024))
    echo "  ✅ Original orthophoto: ${original_size_mb}MB"
    
    if [ "$original_size_mb" -gt 200 ]; then
        echo "     ⚠️  Large file - may cause crashes"
    fi
else
    echo "  ❌ Original orthophoto: Missing"
fi

if [ -f "all/odm_orthophoto/odm_orthophoto_web.tif" ]; then
    web_size=$(stat -c%s "all/odm_orthophoto/odm_orthophoto_web.tif" 2>/dev/null || echo "0")
    web_size_mb=$((web_size / 1024 / 1024))
    echo "  ✅ Web orthophoto: ${web_size_mb}MB"
    
    if [ "$web_size_mb" -gt 100 ]; then
        echo "     ⚠️  Still large - consider smaller scale"
    elif [ "$web_size_mb" -lt 10 ]; then
        echo "     ⚠️  Very small - may have low quality"
    else
        echo "     ✅ Good size for web viewing"
    fi
else
    echo "  ❌ Web orthophoto: Missing - run optimization"
fi

echo ""

# Check system resources
echo "💻 System Status:"
if command -v free &> /dev/null; then
    available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    used_mem=$((total_mem - available_mem))
    
    echo "  Memory: ${used_mem}MB used / ${total_mem}MB total (${available_mem}MB free)"
    
    if [ "$available_mem" -lt 512 ]; then
        echo "     ⚠️  Low memory - crashes likely"
    elif [ "$available_mem" -lt 1000 ]; then
        echo "     ⚠️  Moderate memory - use small files"
    else
        echo "     ✅ Good memory availability"
    fi
else
    echo "  Memory: Cannot check"
fi

if command -v df &> /dev/null; then
    available_space=$(df . | tail -1 | awk '{print $4}')
    available_space_mb=$((available_space / 1024))
    echo "  Disk space: ${available_space_mb}MB available"
    
    if [ "$available_space_mb" -lt 100 ]; then
        echo "     ⚠️  Low disk space"
    else
        echo "     ✅ Sufficient disk space"
    fi
fi

echo ""

# Check running processes
echo "🔄 Running Processes:"
if pgrep -f "python.*http.server" > /dev/null; then
    echo "  ✅ Python HTTP server is running"
    ports=$(lsof -ti -sTCP:LISTEN | xargs -I {} lsof -nP -p {} | grep LISTEN | awk '{print $9}' | cut -d: -f2 | sort -u 2>/dev/null || echo "unknown")
    echo "     Ports: $ports"
else
    echo "  ❌ No HTTP server running"
fi

echo ""

# Recommendations
echo "🎯 Recommendations:"

if [ ! -f "all/odm_orthophoto/odm_orthophoto_web.tif" ]; then
    echo "  1. Run optimization: ./optimize_for_crashes.sh"
fi

if ! pgrep -f "python.*http.server" > /dev/null; then
    echo "  2. Start server: ./start_safe.sh"
fi

if [ -f "all/odm_orthophoto/odm_orthophoto_web.tif" ]; then
    web_size=$(stat -c%s "all/odm_orthophoto/odm_orthophoto_web.tif" 2>/dev/null || echo "0")
    web_size_mb=$((web_size / 1024 / 1024))
    
    if [ "$web_size_mb" -gt 100 ]; then
        echo "  3. Re-optimize with smaller scale: ./optimize_for_crashes.sh 0.3"
    fi
fi

if command -v free &> /dev/null; then
    available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [ "$available_mem" -lt 1000 ]; then
        echo "  4. Close other applications to free memory"
    fi
fi

echo ""
echo "🌐 Access your app at: http://localhost:3004 (once server is running)"