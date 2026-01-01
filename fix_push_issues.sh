#!/bin/bash
# Fix git push by increasing buffer and using better compression

echo "🔧 Fixing Git Push Issues"
echo "========================="
echo ""

# Increase git buffers
echo "Setting larger git buffers..."
git config http.postBuffer 524288000  # 500MB
git config http.maxRequestBuffer 100M
git config core.compression 0
git config pack.windowMemory "100m"
git config pack.packSizeLimit "100m"
git config pack.threads "1"

echo "✅ Git configuration updated"
echo ""

# Check repository size
REPO_SIZE=$(du -sh .git | cut -f1)
echo "Repository size: $REPO_SIZE"
echo ""

# Try to push with better error handling
echo "Attempting to push..."
echo ""

if git push origin main 2>&1 | tee push_output.log; then
    echo ""
    echo "🎉 SUCCESS! Push completed."
    rm -f push_output.log
else
    echo ""
    echo "⚠️  Push still failing. The repository history contains large files."
    echo ""
    echo "📋 Options:"
    echo ""
    echo "Option 1: Push with shallow history (recommended)"
    echo "  git push origin main --force-with-lease"
    echo ""
    echo "Option 2: Clean git history completely (removes large files from history)"
    echo "  Run: ./clean_git_history.sh"
    echo ""
    echo "Option 3: Create a fresh repository"
    echo "  1. Rename current repo on GitHub"
    echo "  2. Create new empty repo"
    echo "  3. Run: ./fresh_commit.sh"
    echo ""
    
    # Create helper script for clean history
    cat > clean_git_history.sh << 'CLEANEOF'
#!/bin/bash
echo "This will rewrite git history to remove large files."
echo "⚠️  WARNING: This is destructive and cannot be undone easily."
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Install git-filter-repo if needed
if ! command -v git-filter-repo &> /dev/null; then
    echo "Installing git-filter-repo..."
    pip3 install git-filter-repo
fi

# Backup
echo "Creating backup..."
cp -r .git .git.backup

# Filter out large files
echo "Filtering large files from history..."
git filter-repo --path all/odm_orthophoto/odm_orthophoto.tif --invert-paths --force
git filter-repo --path all/odm_orthophoto/odm_orthophoto_web.tif --invert-paths --force
git filter-repo --path-glob 'all/entwine_pointcloud/ept-data/*.laz' --invert-paths --force
git filter-repo --path all/odm_georeferencing/odm_georeferenced_model.laz --invert-paths --force

echo "✅ History cleaned!"
echo "Now run: git push origin main --force"
CLEANEOF
    chmod +x clean_git_history.sh
    
    # Create helper script for fresh commit
    cat > fresh_commit.sh << 'FRESHEOF'
#!/bin/bash
echo "Creating fresh repository with clean history"
echo "============================================"
echo ""

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)

# Create orphan branch (no history)
git checkout --orphan fresh-main

# Add all files (respecting .gitignore)
git add -A

# Commit
git commit -m "Initial commit: Drone mapping application with crash prevention

Features:
- Memory-conscious orthophoto loading
- Comprehensive error handling
- Optimization tools for large files
- System monitoring and safe startup
- Interactive testing suite
- Complete documentation

Large data files excluded via .gitignore"

# Replace old main
git branch -D main 2>/dev/null || true
git branch -m fresh-main main

echo ""
echo "✅ Fresh repository created!"
echo ""
echo "Now push with: git push origin main --force"
FRESHEOF
    chmod +x fresh_commit.sh
fi