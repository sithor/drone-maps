# Quick Start: Fix Slow Orthophoto Loading

Your 331MB orthophoto is too large for fast web loading. Here's how to fix it in 2 steps:

## Step 1: Run This Command

```bash
chmod +x setup_and_optimize.sh && ./setup_and_optimize.sh
```

This will:
- Install GDAL (if needed)
- Create a smaller version at 50% scale (~82MB)
- Keep your original file safe

## Step 2: Restart Your Server

```bash
# If server is running in background:
fg
# Then press Ctrl+C

# Restart:
python3 -m http.server 3004
```

## Done! 🎉

Your map will now load **3-4x faster** using `odm_orthophoto_web.tif`.

---

## Want Different Quality?

### Smaller file (faster, lower quality):
```bash
./downsize.sh 25  # 25% scale = ~20MB
```

### Higher quality (slower, better detail):
```bash
./downsize.sh 75  # 75% scale = ~185MB
```

---

## Files Created

- `odm_orthophoto_web.tif` - Your optimized orthophoto
- `downsize.sh` - Script to create optimized versions
- `downsize_orthophoto.py` - Python alternative
- `setup_and_optimize.sh` - One-command setup

Your original `odm_orthophoto.tif` is never modified!

---

## Troubleshooting

**"Permission denied"**
```bash
chmod +x setup_and_optimize.sh
```

**Want to see details?**
Read [OPTIMIZE_ORTHOPHOTO.md](OPTIMIZE_ORTHOPHOTO.md) for full guide.
