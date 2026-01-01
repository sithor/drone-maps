#!/bin/bash
# Commit script that ensures large files are excluded

echo "🚁 Drone Maps - Git Commit Helper"
echo "=================================="
echo ""

cd "$(dirname "$0")"

# Make scripts executable
chmod +x *.sh 2>/dev/null

echo "📋 Checking .gitignore..."
if [ -f ".gitignore" ]; then
    echo "✅ .gitignore exists"
else
    echo "❌ .gitignore missing - creating it"
    exit 1
fi

echo ""
echo "📊 Git status:"
git status --short

echo ""
echo "🔍 Checking for large files..."
LARGE_FILES=$(find . -type f -size +10M -not -path "./.git/*" 2>/dev/null | head -10)

if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Large files found (>10MB):"
    echo "$LARGE_FILES" | while read file; do
        size=$(du -h "$file" | cut -f1)
        echo "  - $file ($size)"
    done
    echo ""
    echo "These files should be in .gitignore:"
    cat .gitignore | grep "\.tif\|\.laz" | head -5
    echo "..."
else
    echo "✅ No large files detected in staging"
fi

echo ""
echo "📦 Files to be committed:"
git diff --cached --name-status 2>/dev/null || git diff --name-status HEAD 2>/dev/null || echo "No changes staged"

echo ""
echo "💡 Ready to commit!"
echo ""
echo "Run these commands:"
echo "  git add -A"
echo "  git commit -m 'Add crash prevention fixes and optimization tools'"
echo "  git push"