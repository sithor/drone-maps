#!/bin/bash
# Clean Git history and deploy

echo "========================================"
echo "Clean Git History & Deploy"
echo "========================================"
echo ""
echo "⚠️  This will rewrite Git history to remove large files"
echo ""

# List of large files to remove from history
LARGE_FILES=(
    "all/odm_dem/dsm.tif"
    "all/odm_dem/dsm_web.tif"
    "all/odm_orthophoto/odm_orthophoto.tif"
    "all/odm_orthophoto/odm_orthophoto_web.tif"
    "all/odm_orthophoto/odm_orthophoto_original.tif"
)

echo "🧹 Removing large files from Git history..."
for file in "${LARGE_FILES[@]}"; do
    echo "   - $file"
    git filter-branch --force --index-filter \
        "git rm --cached --ignore-unmatch '$file'" \
        --prune-empty --tag-name-filter cat -- --all 2>/dev/null
done

echo ""
echo "🗑️  Cleaning up..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "📦 Staging current changes..."
git add .

echo ""
echo "💾 Committing..."
git commit -m "Add 3D terrain-aware measurements (code only)" || echo "Nothing to commit"

echo ""
echo "🚀 Force pushing to GitHub (rewriting history)..."
git push origin main --force

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ SUCCESS!"
    echo "========================================"
    echo ""
    echo "📝 To enable GitHub Pages:"
    echo "1. Go to: https://github.com/sithor/drone-maps/settings/pages"
    echo "2. Set Source: Deploy from a branch"
    echo "3. Set Branch: main / (root)"
    echo "4. Click Save"
    echo ""
    echo "⚠️  Note: Large data files (orthophoto/DEM) are excluded."
    echo "    The code is deployed but will need data files hosted separately."
else
    echo ""
    echo "❌ Push still failed. The repository may be too large."
    echo "Consider creating a fresh repository with just the code."
fi
