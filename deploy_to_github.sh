#!/bin/bash
# Deploy drone mapping site to GitHub Pages

echo "========================================"
echo "GitHub Deployment Script"
echo "========================================"
echo ""

# 1. Stage all changes
echo "📦 Staging changes..."
git add app.js index.html downsize_dem.py downsize_dem.sh reproject_dem.sh all/odm_dem/dsm_web.tif all/odm_orthophoto/odm_orthophoto_web.tif

# 2. Commit
echo ""
echo "💾 Committing changes..."
git commit -m "Add 3D terrain-aware measurements with high-resolution orthophoto

- Increased orthophoto resolution to 1024 for maximum quality
- Added DEM reprojection script for 3D elevation measurements
- Implemented terrain-aware distance and area measurements
- Distance tool shows 3D distance, elevation gain/loss
- Area tool shows 3D perimeter and average elevation
- Restricted map to 3km boundary around survey site
- Optimized DEM and orthophoto for web viewing"

# 3. Push to GitHub
echo ""
echo "🚀 Pushing to GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ SUCCESS!"
    echo "========================================"
    echo ""
    echo "📝 Next steps to enable GitHub Pages:"
    echo ""
    echo "1. Go to: https://github.com/sithor/drone-maps/settings/pages"
    echo "2. Under 'Source', select: Deploy from a branch"
    echo "3. Under 'Branch', select: main"
    echo "4. Under 'Folder', select: / (root)"
    echo "5. Click 'Save'"
    echo ""
    echo "Your site will be live at:"
    echo "https://sithor.github.io/drone-maps/"
    echo ""
    echo "(It may take a few minutes to deploy)"
else
    echo ""
    echo "❌ Push failed. Please check your credentials and try again."
fi
