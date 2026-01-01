# Downsizing Orthophoto Instructions

Your orthophoto file (`odm_orthophoto.tif`) is **331MB**, which causes slow loading times in the browser.

## Quick Solution

### Option 1: Using the Python Script (Recommended)

1. **Install GDAL** (if not already installed):
   ```bash
   sudo apt-get update
   sudo apt-get install gdal-bin
   ```

2. **Run the downsizing script**:
   ```bash
   python3 downsize_orthophoto.py
   ```
   
   This will create a smaller version at 50% scale (~82MB).
   
   To use a different scale (e.g., 30% for even smaller file):
   ```bash
   python3 downsize_orthophoto.py 0.3
   ```

3. **The code will be automatically updated** to use the new file.

### Option 2: Manual GDAL Command

If you prefer to run the command directly:

```bash
gdal_translate \
  -outsize 50% 50% \
  -co COMPRESS=JPEG \
  -co JPEG_QUALITY=85 \
  -co TILED=YES \
  all/odm_orthophoto/odm_orthophoto.tif \
  all/odm_orthophoto/odm_orthophoto_web.tif
```

### Option 3: Create Multiple Resolutions

For even better performance, create a very small preview version:

```bash
# Small preview (25% scale, ~20MB)
gdal_translate \
  -outsize 25% 25% \
  -co COMPRESS=JPEG \
  -co JPEG_QUALITY=80 \
  -co TILED=YES \
  all/odm_orthophoto/odm_orthophoto.tif \
  all/odm_orthophoto/odm_orthophoto_preview.tif
```

## Expected Results

| Scale | File Size | Quality | Use Case |
|-------|-----------|---------|----------|
| 25%   | ~20 MB    | Good    | Fast preview |
| 50%   | ~82 MB    | Great   | General web use |
| 75%   | ~185 MB   | Excellent | High detail needs |

## After Downsizing

The app will automatically use the new `odm_orthophoto_web.tif` file, which should load significantly faster!

## Troubleshooting

If GDAL installation fails, try:
```bash
# For Ubuntu/Debian
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
sudo apt-get install gdal-bin python3-gdal
```
