#!/bin/bash
# Quick script to stage and push changes

echo "Staging all changes..."
git add -A

echo ""
echo "Current status:"
git status

echo ""
echo "Committing changes..."
git commit -m "Remove texture files and optimize repository"

echo ""
echo "Pushing to GitHub..."
git push origin main

echo ""
echo "Done!"
