#!/bin/bash
# Deploy only code to GitHub (exclude large data files)

echo "========================================"
echo "GitHub Pages Deployment (Code Only)"
echo "========================================"
echo ""

# 1. Reset the staging area
echo "🔄 Resetting staged files..."
git reset

# 2. Remove large files from git cache if they were tracked
echo "🧹 Removing large files from git tracking..."
git rm --cached all/odm_dem/dsm_web.tif 2>/dev/null || true
git rm --cached all/odm_orthophoto/*.tif 2>/dev/null || true

# 3. Stage only code files (not data)
echo "📦 Staging code files..."
git add app.js index.html .gitignore
git add downsize_dem.py downsize_dem.sh reproject_dem.sh deploy_to_github.sh
git add *.md *.sh *.html *.js 2>/dev/null || true

# 4. Check what will be committed
echo ""
echo "📋 Files to be committed:"
git status --short

# 5. Commit
echo ""
echo "💾 Committing changes..."
git commit -m "Add 3D terrain-aware measurements and high-resolution viewer

Features:
- Terrain-aware distance measurements (3D distance, elevation gain/loss)
- Terrain-aware area measurements (3D perimeter, average elevation)
- High-resolution orthophoto rendering (1024px tiles)
- DEM reprojection tools for coordinate system conversion
- 3km boundary restriction around survey site
- Optimized for web viewing

Note: Large data files (orthophoto, DEM) not included in repo
Upload them separately to your web server"

# 6. Push to GitHub
echo ""
echo "🚀 Pushing to GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ CODE DEPLOYED!"
    echo "========================================"
    echo ""
    echo "⚠️  IMPORTANT: Your data files are NOT in GitHub"
    echo ""
    echo "To make your site work, you need to:"
    echo "1. Enable GitHub Pages (see instructions below)"
    echo "2. Upload these files to your web server:"
    echo "   - all/odm_orthophoto/odm_orthophoto_web.tif"
    echo "   - all/odm_dem/dsm_web.tif"
    echo ""
    echo "📝 Enable GitHub Pages:"
    echo "1. Go to: https://github.com/sithor/drone-maps/settings/pages"
    echo "2. Source: Deploy from a branch"
    echo "3. Branch: main, Folder: / (root)"
    echo "4. Click 'Save'"
    echo ""
    echo "Site will be at: https://sithor.github.io/drone-maps/"
else
    echo ""
    echo "❌ Push failed. Check the error above."
fi
