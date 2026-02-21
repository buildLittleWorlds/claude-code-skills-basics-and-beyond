#!/usr/bin/env bash
# setup-tasks.sh — Bootstrap the task directory with seed data
#
# Run once to create ~/work/_tasks/ and populate it with
# realistic test data for the Phase 3 tutorial.
#
# Usage:
#   bash skills/courses/phase3/setup-tasks.sh
#
# Re-running is safe: it skips directories that already exist
# and only copies files that don't already have a counterpart.

set -e

TASKS_DIR="$HOME/work/_tasks"
SEED_DIR="$(cd "$(dirname "$0")" && pwd)/seed-tasks"

# ── Create directory structure ──────────────────────────────
echo "Setting up task directories..."

for dir in inbox pending archive log; do
    if [ -d "$TASKS_DIR/$dir" ]; then
        echo "  ✓ $TASKS_DIR/$dir already exists"
    else
        mkdir -p "$TASKS_DIR/$dir"
        echo "  + Created $TASKS_DIR/$dir"
    fi
done

# ── Copy seed files ─────────────────────────────────────────
echo ""
echo "Copying seed data..."

copied=0
skipped=0

for dir in inbox pending archive log; do
    if [ -d "$SEED_DIR/$dir" ]; then
        for file in "$SEED_DIR/$dir"/*.md; do
            [ -f "$file" ] || continue
            basename="$(basename "$file")"
            if [ -f "$TASKS_DIR/$dir/$basename" ]; then
                skipped=$((skipped + 1))
            else
                cp "$file" "$TASKS_DIR/$dir/$basename"
                copied=$((copied + 1))
                echo "  + $dir/$basename"
            fi
        done
    fi
done

echo ""
echo "Done. Copied $copied files, skipped $skipped existing."

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "Your task directory:"
echo ""
for dir in inbox pending archive log; do
    count=$(ls -1 "$TASKS_DIR/$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "  $TASKS_DIR/$dir/  ($count files)"
done
echo ""
echo "Next: Open the Phase 3 tutorial and start Lesson 1."
