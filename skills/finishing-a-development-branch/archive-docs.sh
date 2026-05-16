#!/bin/bash
# skills/finishing-a-development-branch/archive-docs.sh
ROOT_DIR=$1
FEATURE_NAME=$2
STATUS=$3 # completed | discarded

ARCHIVE_SUBDIR="archive"
if [ "$STATUS" == "discarded" ]; then
    ARCHIVE_SUBDIR="archive/discarded"
fi

echo "[Archive] Archiving documentation for: $FEATURE_NAME"

# Find files
FILES=$(find "$ROOT_DIR/docs/superpowers" -name "*-$FEATURE_NAME*.md" -not -path "*/archive/*")

if [ -z "$FILES" ]; then
    echo "  - No matching documents found. Skipping."
    exit 0
fi

# Prepare archive dirs
mkdir -p "$ROOT_DIR/docs/superpowers/specs/$ARCHIVE_SUBDIR"
mkdir -p "$ROOT_DIR/docs/superpowers/plans/$ARCHIVE_SUBDIR"

for FILE in $FILES; do
    BASENAME=$(basename "$FILE")
    DIRNAME=$(dirname "$FILE")
    TYPE=$(basename "$DIRNAME") # specs or plans
    DEST="$ROOT_DIR/docs/superpowers/$TYPE/$ARCHIVE_SUBDIR/$BASENAME"
    
    echo "  - Moving $TYPE: docs/superpowers/$TYPE/$BASENAME -> docs/superpowers/$TYPE/$ARCHIVE_SUBDIR/$BASENAME"
    
    # Simple link update: ../plans/ -> ./ (when both are in archive)
    # Using a portable sed approach
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|\](../plans/|\](|g" "$FILE"
        sed -i '' "s|\](../specs/|\](|g" "$FILE"
    else
        sed -i "s|\](../plans/|\](|g" "$FILE"
        sed -i "s|\](../specs/|\](|g" "$FILE"
    fi
    
    mv "$FILE" "$DEST"
    # Stage the move in git if in a git repo
    if [ -d "$ROOT_DIR/.git" ]; then
        git -C "$ROOT_DIR" add "$DEST" "$FILE" 2>/dev/null || true
    fi
done

echo "  - Committing to git..."
if [ -d "$ROOT_DIR/.git" ]; then
    git -C "$ROOT_DIR" commit -m "docs: archive $FEATURE_NAME [$STATUS]" --no-verify 2>/dev/null || true
fi
echo "✅ Documentation archived to $ARCHIVE_SUBDIR/ directory."
