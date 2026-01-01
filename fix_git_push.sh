#!/bin/bash
# Script to remove large files from git and push successfully

echo "🔧 Fixing Git Push - Removing Large Files from History"
echo "======================================================="
echo ""

cd "$(dirname "$0")"

echo "Step 1: Check current repository size..."
git count-objects -vH

echo ""
echo "Step 2: Finding large files in git history..."
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  sed -n 's/^blob //p' | \
  sort --numeric-sort --key=2 | \
  tail -n 10

echo ""
echo "Step 3: Removing large files from git tracking..."

# Remove large orthophoto files if they're tracked
git rm --cached 'all/odm_orthophoto/*.tif' 2>/dev/null || true
git rm --cached 'all/odm_orthophoto/*.tiff' 2>/dev/null || true

# Remove point cloud files if they're tracked  
git rm --cached 'all/entwine_pointcloud/ept-data/*.laz' 2>/dev/null || true
git rm --cached 'all/odm_georeferencing/*.laz' 2>/dev/null || true

# Remove texturing files if they're tracked
git rm --cached 'all/odm_texturing/*.obj' 2>/dev/null || true
git rm --cached 'all/odm_texturing/*.mtl' 2>/dev/null || true

echo ""
echo "Step 4: Verify .gitignore is in place..."
if [ -f ".gitignore" ]; then
    echo "✅ .gitignore exists and will prevent re-adding these files"
else
    echo "❌ .gitignore missing!"
    exit 1
fi

echo ""
echo "Step 5: Check what's left to commit..."
git status --short

echo ""
echo "================================================================"
echo "✅ Large files removed from git tracking!"
echo ""
echo "Next steps:"
echo "1. Commit the removal:"
echo "   git commit -m 'Remove large data files from git tracking'"
echo ""
echo "2. Push to GitHub:"
echo "   git push origin main"
echo ""
echo "The large files will remain on your local disk but won't be"
echo "pushed to GitHub (they're now in .gitignore)"
echo "================================================================"