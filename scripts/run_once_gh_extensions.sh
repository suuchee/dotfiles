#!/bin/bash

if ! command -v gh &> /dev/null; then
  echo "⚠️  gh is not installed, skipping gh extension installation."
  exit 0
fi

extensions=(
  "charmbracelet/gh-markdown-preview"
)

for ext in "${extensions[@]}"; do
  if gh extension list | grep -q "$ext"; then
    echo "✅ gh extension $ext already installed"
  else
    echo "📦 Installing gh extension $ext..."
    gh extension install "$ext"
  fi
done
