#!/bin/bash
# Remove all large data files from Git history

echo "========================================"
echo "Remove All Large Data Files"
echo "========================================"
echo ""

export FILTER_BRANCH_SQUELCH_WARNING=1

echo "🧹 Removing ALL data files from Git history..."
echo "   This will keep only code files (HTML, JS, CSS, shell scripts, docs)"
echo ""

# Remove entire data directories from history
git filter-branch --force --index-filter \
    'git rm -r --cached --ignore-unmatch all/odm_dem all/odm_georeferencing all/odm_orthophoto all/odm_texturing all/odm_report all/entwine_pointcloud' \
    --prune-empty --tag-name-filter cat -- --all

echo ""
echo "🗑️  Cleaning up..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "📝 Updating .gitignore to exclude all data..."
cat > .gitignore << 'EOF'
# Data files (too large for GitHub)
all/odm_dem/
all/odm_georeferencing/
all/odm_orthophoto/
all/odm_texturing/
all/odm_report/
all/entwine_pointcloud/

# Keep only JSON metadata
!all/*.json
!all/odm_report/*.json

# Python
__pycache__/
*.pyc

# OS
.DS_Store
Thumbs.db
EOF

echo ""
echo "📦 Staging changes..."
git add .gitignore
git add app.js index.html *.sh *.py *.md

echo ""
echo "💾 Committing..."
git commit -m "Deploy code only - removed all large data files

This commit contains only the web application code.
Data files (DEM, orthophoto, point clouds) are excluded.

To use locally:
1. Place your data files in the all/ directory
2. Run: ./reproject_dem.sh (for DEM)
3. Run: python3 -m http.server 8080
4. Open: http://localhost:8080" || echo "Nothing new to commit"

echo ""
echo "🚀 Force pushing clean repository..."
git push origin main --force

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ SUCCESS!"
    echo "========================================"
    echo ""
    echo "🎉 Code successfully deployed to GitHub!"
    echo ""
    echo "📝 To enable GitHub Pages:"
    echo "1. Go to: https://github.com/sithor/drone-maps/settings/pages"
    echo "2. Source: Deploy from a branch"
    echo "3. Branch: main / (root)"
    echo "4. Click Save"
    echo ""
    echo "⚠️  Important: The deployed site won't have data files."
    echo "   To make it work online, you need to:"
    echo "   - Host data files on a separate service (AWS S3, Cloudflare R2, etc.)"
    echo "   - Update the file paths in app.js"
    echo ""
    echo "   OR keep using it locally where you have the data files."
else
    echo ""
    echo "❌ Push failed again. Check the error above."
fi
