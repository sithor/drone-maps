# 🧪 Testing Your Crash Fixes

## Quick Test Guide

### Method 1: Use the Test Page

1. **Start your server** (if not already running):
   ```bash
   python3 -m http.server 8000
   ```

2. **Open the test page** in your browser:
   ```
   http://localhost:8000/test_fixes.html
   ```

3. **Run the tests** by clicking the buttons:
   - ✅ Library loading status
   - ✅ Error handling mechanisms
   - ✅ Memory management
   - ✅ File detection and sizing
   - ✅ System status

### Method 2: Test the Main Application

1. **Resume or restart your server**:
   ```bash
   # If you have a stopped server (from Ctrl+Z):
   fg  # Then Ctrl+C to stop it
   
   # Start fresh:
   python3 -m http.server 8000
   ```

2. **Open the main application**:
   ```
   http://localhost:8000/index.html
   ```

3. **Check the browser console** (F12 or right-click → Inspect):
   - Should see: "GeoTIFF info:" with file details
   - Should see: "✅ Orthophoto loaded successfully!"
   - No red errors about crashes

### Method 3: Run Status Check

```bash
chmod +x check_status.sh
./check_status.sh
```

This will show:
- File sizes and status
- System memory and disk space
- Running processes
- Recommendations

---

## What to Look For

### ✅ Good Signs (Fixes Working):
- Application loads without freezing
- Progress messages: "Loading orthophoto..." → "Downloading..." → "Processing..." → "Rendering..."
- Map displays with satellite imagery
- Controls are responsive (opacity slider, measurement tools)
- Console shows success messages
- No browser tab crashes

### ⚠️ Warning Signs (Need More Optimization):
- Loading takes more than 10 seconds
- Browser tab shows high memory usage
- Console warnings about file size
- Slow zoom/pan performance

### ❌ Error Signs (Additional Issues):
- Red error box appears
- Console shows "Failed to load orthophoto"
- Browser tab crashes or becomes unresponsive
- Network errors for missing files

---

## Expected Results After Fixes

### Before Fixes:
- 🔴 Browser crash on load (331MB file)
- 🔴 No error recovery
- 🔴 Infinite loading loops
- 🔴 Codespaces freezing

### After Fixes:
- ✅ Handles large files gracefully
- ✅ Shows helpful error messages
- ✅ Automatic fallback to smaller files
- ✅ Memory-conscious loading
- ✅ Progress indicators
- ✅ Recovery options (retry button)

---

## Testing Each Crash Prevention Feature

### 1. **Memory Management**
Test: Open browser DevTools → Performance tab → Start recording while loading map
- Expected: Gradual memory increase, then stable
- Bad: Rapid spike, then crash

### 2. **Error Recovery**
Test: Rename `odm_orthophoto_web.tif` temporarily
- Expected: Error message with instructions and retry button
- Bad: White screen or crash

### 3. **File Size Detection**
Test: Check console logs when loading
- Expected: "File size: XX.X MB" logged
- Bad: No size check, immediate crash

### 4. **Loading State Protection**
Test: Refresh page multiple times rapidly
- Expected: Only one load attempt, others ignored
- Bad: Multiple simultaneous loads, crash

### 5. **Library Loading Protection**
Test: Disconnect internet, reload page
- Expected: Error about missing libraries with refresh button
- Bad: Blank page, no feedback

---

## Performance Benchmarks

### Target Performance (After Fixes):
| Metric | Target | Original |
|--------|--------|----------|
| Load Time | < 5 seconds | 30+ seconds or crash |
| Memory Usage | < 500MB | 1GB+ or crash |
| File Size | 20-80MB | 331MB |
| Responsiveness | Smooth zoom/pan | Laggy or frozen |
| Error Recovery | Automatic | None |

---

## If Tests Fail

### Issue: Application still crashes
**Solution**: Run smaller optimization
```bash
./optimize_for_crashes.sh 0.25
```

### Issue: Test page doesn't load libraries
**Solution**: Check internet connection, CDN may be blocked

### Issue: No files found
**Solution**: Verify ODM output exists
```bash
ls -lh all/odm_orthophoto/
```

### Issue: Out of memory errors
**Solution**: Close other applications, use smaller file scale

---

## Browser Console Commands for Testing

Open DevTools console (F12) and try:

```javascript
// Check if crash prevention is active
console.log('Loading state:', isLoading);
console.log('Abort controller:', loadingAbortController);

// Check map status
console.log('Map initialized:', typeof map !== 'undefined');
console.log('Layer loaded:', orthophotoLayer !== null);

// Check memory (Chrome only)
if (performance.memory) {
    console.log('Memory used:', 
        (performance.memory.usedJSHeapSize / 1048576).toFixed(2) + ' MB');
}
```

---

## Success Indicators

You'll know the fixes are working when:

1. ✅ Application loads in under 10 seconds
2. ✅ No browser tab crashes during load
3. ✅ Clear progress messages in UI
4. ✅ Error messages are helpful (not cryptic)
5. ✅ Can zoom and pan smoothly
6. ✅ Console shows "✅ Orthophoto loaded successfully!"
7. ✅ Codespace remains responsive
8. ✅ Multiple page refreshes don't cause issues

---

## Next Steps After Successful Test

1. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Add crash prevention fixes"
   git push
   ```

2. **Monitor performance**: Check browser memory usage over time

3. **Scale as needed**: If still slow, re-optimize with smaller scale

4. **Share**: The application should now be safe to share with others!

---

## Quick Reference

| Action | Command |
|--------|---------|
| Start server | `python3 -m http.server 8000` |
| Check status | `./check_status.sh` |
| Optimize files | `./optimize_for_crashes.sh` |
| Safe start | `./start_safe.sh` |
| View main app | `http://localhost:8000/` |
| View test page | `http://localhost:8000/test_fixes.html` |