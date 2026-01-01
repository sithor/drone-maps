#!/bin/bash
# Safe startup script for drone maps application

echo "🚁 Drone Maps - Safe Startup"
echo "============================"
echo ""

# Navigate to correct directory
cd "$(dirname "$0")"

# Function to check if port is in use
check_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        lsof -ti:$port > /dev/null 2>&1
    elif command -v netstat &> /dev/null; then
        netstat -ln | grep ":$port " > /dev/null 2>&1
    else
        # Fallback: try to bind to port
        python3 -c "import socket; s=socket.socket(); s.bind(('', $port)); s.close()" 2>/dev/null
        return $?
    fi
}

# Function to kill processes on port
kill_port() {
    local port=$1
    echo "Cleaning up processes on port $port..."
    
    if command -v lsof &> /dev/null; then
        lsof -ti:$port | xargs -r kill 2>/dev/null
    fi
    
    # Kill common server processes
    pkill -f "python.*http.server.*$port" 2>/dev/null || true
    pkill -f "python.*-m.*http.server.*$port" 2>/dev/null || true
    
    sleep 1
}

# Check system resources
echo "📊 System Check"
echo "---------------"

# Check available memory
if command -v free &> /dev/null; then
    available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    echo "Available memory: ${available_mem}MB"
    
    if [ "$available_mem" -lt 512 ]; then
        echo "⚠️  WARNING: Low memory (${available_mem}MB)"
        echo "   The application may crash with large files"
        echo "   Consider optimizing your orthophoto first"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted. Run ./optimize_for_crashes.sh first"
            exit 1
        fi
    else
        echo "✅ Memory OK"
    fi
else
    echo "ℹ️  Memory check not available"
fi

# Check disk space
if command -v df &> /dev/null; then
    available_space=$(df . | tail -1 | awk '{print $4}')
    available_space_mb=$((available_space / 1024))
    echo "Available disk space: ${available_space_mb}MB"
    
    if [ "$available_space_mb" -lt 100 ]; then
        echo "⚠️  WARNING: Low disk space (${available_space_mb}MB)"
        echo "   The application may not work properly"
    else
        echo "✅ Disk space OK"
    fi
else
    echo "ℹ️  Disk space check not available"
fi

echo ""

# Check if orthophoto files exist
echo "📁 File Check"
echo "-------------"

ORIGINAL_PHOTO="all/odm_orthophoto/odm_orthophoto.tif"
WEB_PHOTO="all/odm_orthophoto/odm_orthophoto_web.tif"

if [ -f "$ORIGINAL_PHOTO" ]; then
    original_size=$(stat -c%s "$ORIGINAL_PHOTO" 2>/dev/null || stat -f%z "$ORIGINAL_PHOTO" 2>/dev/null || echo "0")
    original_size_mb=$((original_size / 1024 / 1024))
    echo "✅ Original orthophoto found (${original_size_mb}MB)"
    
    if [ "$original_size_mb" -gt 200 ]; then
        echo "⚠️  Large file detected - may cause crashes"
    fi
else
    echo "❌ Original orthophoto not found: $ORIGINAL_PHOTO"
    echo "   Make sure ODM processing completed successfully"
    exit 1
fi

if [ -f "$WEB_PHOTO" ]; then
    web_size=$(stat -c%s "$WEB_PHOTO" 2>/dev/null || stat -f%z "$WEB_PHOTO" 2>/dev/null || echo "0")
    web_size_mb=$((web_size / 1024 / 1024))
    echo "✅ Web-optimized photo found (${web_size_mb}MB)"
    
    if [ "$web_size_mb" -gt 100 ]; then
        echo "⚠️  Web version still large - consider re-optimizing"
    fi
else
    echo "⚠️  Web-optimized photo not found"
    echo "   Recommending optimization..."
    echo ""
    read -p "Run optimization now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if [ -f "optimize_for_crashes.sh" ]; then
            chmod +x optimize_for_crashes.sh
            ./optimize_for_crashes.sh
        else
            echo "❌ Optimization script not found"
            exit 1
        fi
    fi
fi

echo ""

# Choose port
PORT=${1:-3004}
echo "🌐 Server Setup"
echo "---------------"

# Clean up any existing servers on this port
if check_port $PORT; then
    echo "Port $PORT is in use"
    kill_port $PORT
    
    # Wait and check again
    sleep 2
    if check_port $PORT; then
        echo "❌ Could not free port $PORT"
        echo "Try using a different port: ./start_safe.sh 3005"
        exit 1
    fi
fi

echo "✅ Port $PORT is available"
echo ""

# Start server with error handling
echo "🚀 Starting Server"
echo "------------------"
echo "Starting Python HTTP server on port $PORT..."
echo "URL: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Try to start server with fallbacks
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m http.server $PORT
else
    echo "❌ Python not found"
    echo "Install Python or use a different web server"
    exit 1
fi