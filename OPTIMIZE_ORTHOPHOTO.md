# Orthophoto Downsizing Guide

## Problem
Your orthophoto (`odm_orthophoto.tif`) is **331MB**, causing slow loading times in the web browser.

## Solution
I've prepared scripts to create a smaller, web-optimized version of your orthophoto that will load much faster.

---

## Quick Start (Easiest Method)

### 1. Install GDAL (one-time setup)
```bash
sudo apt-get update && sudo apt-get install -y gdal-bin
```

### 2. Run the downsize script
```bash
chmod +x downsize.sh
./downsize.sh
```

This creates `odm_orthophoto_web.tif` at 50% scale (~82MB) - a **75% size reduction**!

### 3. Restart your web server
```bash
# Stop the current server (Ctrl+C or fg then Ctrl+C)
# Then restart:
python3 -m http.server 3004
```

The page will now load the optimized version automatically! 🚀

---

## Alternative: Use Python Script

```bash
python3 downsize_orthophoto.py
```

Or specify a custom scale (0.1 to 1.0):
```bash
python3 downsize_orthophoto.py 0.3  # 30% scale for very small file
python3 downsize_orthophoto.py 0.75  # 75% scale for better quality
```

---

## Recommended Scales

| Scale | Approx Size | Best For |
|-------|-------------|----------|
| `0.25` | ~20 MB | Mobile users, slow connections |
| `0.50` | ~82 MB | General web use (recommended) |
| `0.75` | ~185 MB | High detail requirements |

---

## Manual Command (Advanced)

If you want full control:

```bash
gdal_translate \
  -outsize 50% 50% \
  -co COMPRESS=JPEG \
  -co JPEG_QUALITY=85 \
  -co TILED=YES \
  all/odm_orthophoto/odm_orthophoto.tif \
  all/odm_orthophoto/odm_orthophoto_web.tif
```

**Options explained:**
- `-outsize 50% 50%` - Reduces dimensions to 50% (25% file size)
- `-co COMPRESS=JPEG` - Uses JPEG compression (good for photos)
- `-co JPEG_QUALITY=85` - Balance of quality and size
- `-co TILED=YES` - Enables efficient partial loading

---

## How It Works

1. **The scripts create a new file**: `odm_orthophoto_web.tif`
2. **Your original file is preserved**: `odm_orthophoto.tif` remains unchanged
3. **The app automatically uses the optimized version**: I've updated `app.js` to:
   - Try loading `odm_orthophoto_web.tif` first
   - Fall back to the original if not found

---

## Troubleshooting

### "gdal_translate: command not found"
Install GDAL:
```bash
sudo apt-get update
sudo apt-get install gdal-bin
```

### "Permission denied" error
Make the script executable:
```bash
chmod +x downsize.sh
```

### Want even smaller files?
Try a lower scale:
```bash
./downsize.sh 25  # 25% scale
```

Or use ImageMagick for aggressive compression:
```bash
sudo apt-get install imagemagick
convert all/odm_orthophoto/odm_orthophoto.tif \
  -resize 50% \
  -quality 80 \
  all/odm_orthophoto/odm_orthophoto_web.tif
```

---

## Performance Comparison

| File | Size | Typical Load Time |
|------|------|-------------------|
| Original | 331 MB | 30-90 seconds |
| 50% Scale | ~82 MB | 8-25 seconds |
| 25% Scale | ~20 MB | 2-6 seconds |

*Times vary based on connection speed and browser*

---

## Need Help?

1. Check that you're in the `/workspaces/drone-maps` directory
2. Verify the original file exists: `ls -lh all/odm_orthophoto/odm_orthophoto.tif`
3. Check GDAL installation: `gdal_translate --version`

---

## What Changed in the Code

I updated [app.js](app.js) to automatically use the web-optimized version:

```javascript
// Try to fetch the web-optimized version first, fallback to original
let orthophotoUrl = 'all/odm_orthophoto/odm_orthophoto_web.tif';
let response = await fetch(orthophotoUrl);

if (!response.ok) {
    console.log('Web-optimized version not found, using original...');
    orthophotoUrl = 'all/odm_orthophoto/odm_orthophoto.tif';
    response = await fetch(orthophotoUrl);
}
```

This means the app works whether or not you've created the optimized version yet!
