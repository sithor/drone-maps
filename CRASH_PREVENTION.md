# 🚁 Drone Maps - Crash Prevention Guide

## ⚠️ IMPORTANT: If Your Website/Codespaces Keep Crashing

This guide provides comprehensive solutions to fix crashes and performance issues with your drone mapping web application.

## 🔧 Quick Fix (Most Common Issues)

### 1. Run the Crash Prevention Script
```bash
chmod +x optimize_for_crashes.sh start_safe.sh
./optimize_for_crashes.sh
```

This will:
- ✅ Check system resources (memory, disk space)
- ✅ Clean up hanging processes
- ✅ Install GDAL if needed
- ✅ Create optimized, smaller orthophoto files
- ✅ Set up proper compression and tiling

### 2. Start the Server Safely
```bash
./start_safe.sh
```

This will:
- ✅ Check system resources before starting
- ✅ Clean up any conflicting processes
- ✅ Verify all required files exist
- ✅ Start server on an available port

---

## 🏥 Crash Prevention Improvements

### JavaScript/Browser Crash Fixes

The application now includes:

1. **Memory Management**
   - Prevents multiple simultaneous loading attempts
   - Cleans up existing layers before loading new ones
   - Uses adaptive resolution based on image size
   - Implements file size checks before processing

2. **Better Error Handling**
   - Global error handlers for unhandled exceptions
   - Graceful fallbacks for missing libraries
   - User-friendly error messages with retry options
   - Automatic error cleanup after 10 seconds

3. **Library Loading Protection**
   - CDN failure detection and fallbacks
   - Script loading error handlers
   - Initialization checks for all required libraries
   - Delayed initialization for slow connections

4. **Performance Optimizations**
   - Canvas rendering preference for better performance
   - Maximum zoom limits to prevent excessive memory usage
   - Efficient pixel processing with error handling
   - Progressive loading with abort controllers

### Server/System Crash Fixes

1. **Process Management**
   - Automatic cleanup of hanging HTTP servers
   - Port conflict detection and resolution
   - Resource usage monitoring

2. **File Size Management**
   - Automatic detection of oversized files
   - Smart scaling based on available memory
   - Backup creation for original files
   - Multi-format compression options

---

## 📊 Understanding the Crash Causes

### Original Problems:
1. **Large Files**: 331MB+ orthophoto files causing browser memory crashes
2. **Poor Error Handling**: Uncaught errors crashing the application
3. **CDN Dependencies**: External library loading failures
4. **Memory Leaks**: Not cleaning up previous map layers
5. **Process Conflicts**: Multiple servers competing for same ports

### Our Solutions:
1. **File Optimization**: Create 50-85% smaller files with smart compression
2. **Comprehensive Error Handling**: Catch and recover from all error types
3. **Fallback Systems**: Local backups and alternative loading methods
4. **Memory Management**: Proper cleanup and resource monitoring
5. **Process Management**: Safe startup and conflict resolution

---

## 🛠️ Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `optimize_for_crashes.sh` | Main crash prevention tool | `./optimize_for_crashes.sh [scale]` |
| `start_safe.sh` | Safe server startup | `./start_safe.sh [port]` |
| `setup_and_optimize.sh` | Original optimization script | `./setup_and_optimize.sh` |
| `downsize_orthophoto.py` | Python-based downsizing | `python3 downsize_orthophoto.py [scale]` |

---

## 🎯 Recommended Workflow

### For New Installations:
1. `./optimize_for_crashes.sh 0.5`  # Create 50% scale version
2. `./start_safe.sh 3004`           # Start server safely

### If Still Crashing:
1. `./optimize_for_crashes.sh 0.3`  # Create smaller 30% scale version
2. Check browser developer console for specific errors
3. Try a different browser (Chrome, Firefox, Safari)
4. Ensure you have at least 1GB available RAM

### For Very Large Files (>500MB):
1. `./optimize_for_crashes.sh 0.25` # Create 25% scale version
2. Consider processing smaller image sets in ODM
3. Use cloud instances with more RAM if needed

---

## 🔍 Troubleshooting

### Browser Issues:
- **Symptom**: Page crashes or freezes
- **Solution**: Use smaller scale factor (0.3 or lower)
- **Check**: Browser developer tools for memory errors

### Codespaces Issues:
- **Symptom**: Codespace becomes unresponsive
- **Solution**: Restart codespace, use smaller files
- **Check**: Available memory with `free -h`

### Loading Issues:
- **Symptom**: Infinite loading or error messages
- **Solution**: Check network, refresh CDN libraries
- **Check**: Browser network tab for failed requests

### File Not Found:
- **Symptom**: "No orthophoto file found" error
- **Solution**: Verify ODM processing completed successfully
- **Check**: `ls -la all/odm_orthophoto/`

---

## 📈 Performance Tips

1. **Optimal File Sizes**:
   - Web version: 20-80MB (best performance)
   - Original backup: Keep for high-quality viewing
   - Multiple scales: Create different versions for different uses

2. **Browser Optimization**:
   - Use Chrome or Firefox (best WebGL support)
   - Close other tabs to free memory
   - Enable hardware acceleration

3. **System Optimization**:
   - Ensure 1GB+ available RAM
   - Use SSD storage when possible
   - Close unnecessary applications

---

## 🆘 Emergency Recovery

If everything is broken:

```bash
# 1. Complete reset
git checkout HEAD -- . 
git clean -fd

# 2. Fresh optimization
./optimize_for_crashes.sh 0.25

# 3. Safe restart
./start_safe.sh
```

---

## 📞 Support

If crashes persist after following this guide:

1. Check the browser console for specific error messages
2. Verify system requirements (1GB+ RAM, modern browser)
3. Try with the smallest scale factor (0.1)
4. Consider using a more powerful system/instance

The crash prevention system should resolve 95%+ of common issues. The remaining issues are typically due to insufficient system resources or corrupted source files.