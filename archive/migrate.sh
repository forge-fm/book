#!/bin/bash
# Migrate book from mdbook to mkdocs format
# Converts admonish syntax and copies all assets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/book/src"
DST="$SCRIPT_DIR/docs"
CONVERT="$SCRIPT_DIR/convert.py"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting migration from mdbook to mkdocs...${NC}"
echo "Source: $SRC"
echo "Destination: $DST"
echo ""

# Clean destination directory
if [ -d "$DST" ]; then
    echo "Cleaning existing docs directory..."
    rm -rf "$DST"
fi
mkdir -p "$DST"

# Function to convert and copy a markdown file
convert_file() {
    local src_file="$1"
    local dst_file="$2"
    mkdir -p "$(dirname "$dst_file")"
    python3 "$CONVERT" "$src_file" > "$dst_file"
    echo -e "${GREEN}Converted:${NC} $(basename "$src_file")"
}

# Function to copy a non-markdown file
copy_file() {
    local src_file="$1"
    local dst_file="$2"
    mkdir -p "$(dirname "$dst_file")"
    cp "$src_file" "$dst_file"
}

# Create MkDocs directories
mkdir -p "$DST/javascripts"
mkdir -p "$DST/stylesheets"

# Create MathJax configuration file
cat > "$DST/javascripts/mathjax.js" << 'EOF'
window.MathJax = {
  tex: {
    inlineMath: [["$", "$"], ["\\(", "\\)"]],
    displayMath: [["$$", "$$"], ["\\[", "\\]"]],
    processEscapes: true,
    processEnvironments: true
  },
  options: {
    ignoreHtmlClass: ".*|",
    processHtmlClass: "arithmatex"
  }
};

document$.subscribe(() => {
  MathJax.startup.output.clearCache()
  MathJax.typesetClear()
  MathJax.texReset()
  MathJax.typesetPromise()
})
EOF

# Create extra CSS file (placeholder)
cat > "$DST/stylesheets/extra.css" << 'EOF'
/* Custom styles for Logic for Systems book */

/* Ensure code blocks don't overflow */
.md-typeset pre > code {
  overflow-x: auto;
}

/* Style for Forge code blocks */
.highlight .language-forge {
  /* Add any Forge-specific styling here */
}
EOF

echo ""
echo -e "${BLUE}Converting markdown files...${NC}"

# ==========================================
# Welcome page -> index.md
# ==========================================
convert_file "$SRC/welcome.md" "$DST/index.md"

# ==========================================
# Main Book Chapters
# ==========================================
echo ""
echo "Processing book chapters..."

# Manifesto / Preamble
convert_file "$SRC/chapters/manifesto/job.md" "$DST/chapters/manifesto/job.md"
convert_file "$SRC/chapters/manifesto/manifesto.md" "$DST/chapters/manifesto/manifesto.md"

# Properties / PBT
convert_file "$SRC/chapters/properties/pbt.md" "$DST/chapters/properties/pbt.md"

# Tic-Tac-Toe
convert_file "$SRC/chapters/ttt/ttt.md" "$DST/chapters/ttt/ttt.md"
convert_file "$SRC/chapters/ttt/ttt_games.md" "$DST/chapters/ttt/ttt_games.md"

# Binary Search Trees
convert_file "$SRC/chapters/bst/bst.md" "$DST/chapters/bst/bst.md"
convert_file "$SRC/chapters/bst/descent.md" "$DST/chapters/bst/descent.md"

# Adder
convert_file "$SRC/chapters/adder/rca.md" "$DST/chapters/adder/rca.md"

# Q&A
convert_file "$SRC/chapters/qna/static.md" "$DST/chapters/qna/static.md"
convert_file "$SRC/chapters/qna/events.md" "$DST/chapters/qna/events.md"
convert_file "$SRC/chapters/qna/relations.md" "$DST/chapters/qna/relations.md"

# Inductive
convert_file "$SRC/chapters/inductive/bsearch.md" "$DST/chapters/inductive/bsearch.md"

# Validation
convert_file "$SRC/chapters/validation/validating_events.md" "$DST/chapters/validation/validating_events.md"

# Relations
convert_file "$SRC/chapters/relations/modeling-booleans-1.md" "$DST/chapters/relations/modeling-booleans-1.md"
convert_file "$SRC/chapters/relations/reachability.md" "$DST/chapters/relations/reachability.md"
convert_file "$SRC/chapters/relations/sets-induction-mutex.md" "$DST/chapters/relations/sets-induction-mutex.md"
convert_file "$SRC/chapters/relations/sets-beyond-assertions.md" "$DST/chapters/relations/sets-beyond-assertions.md"

# Temporal
convert_file "$SRC/chapters/temporal/liveness_and_lassos.md" "$DST/chapters/temporal/liveness_and_lassos.md"
convert_file "$SRC/chapters/temporal/temporal_operators.md" "$DST/chapters/temporal/temporal_operators.md"
convert_file "$SRC/chapters/temporal/temporal_operators_2.md" "$DST/chapters/temporal/temporal_operators_2.md"
convert_file "$SRC/chapters/temporal/obligations_past.md" "$DST/chapters/temporal/obligations_past.md"
convert_file "$SRC/chapters/temporal/fixing_lock_temporal.md" "$DST/chapters/temporal/fixing_lock_temporal.md"
convert_file "$SRC/chapters/temporal/testing_temporal.md" "$DST/chapters/temporal/testing_temporal.md"

# Solvers
convert_file "$SRC/chapters/solvers/bounds_booleans_how_forge_works.md" "$DST/chapters/solvers/bounds_booleans_how_forge_works.md"
convert_file "$SRC/chapters/solvers/dpll.md" "$DST/chapters/solvers/dpll.md"
convert_file "$SRC/chapters/solvers/resolution.md" "$DST/chapters/solvers/resolution.md"
convert_file "$SRC/chapters/solvers/smt.md" "$DST/chapters/solvers/smt.md"
convert_file "$SRC/chapters/solvers/cegis.md" "$DST/chapters/solvers/cegis.md"

# Appendix
convert_file "$SRC/appendix/glossary.md" "$DST/appendix/glossary.md"
convert_file "$SRC/appendix/errors.md" "$DST/appendix/errors.md"

# ==========================================
# Copy images and other assets
# ==========================================
echo ""
echo -e "${BLUE}Copying images and assets...${NC}"

# Copy all images from chapters (excluding sat_demo)
find "$SRC/chapters" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.svg" -o -name "*.gif" \) | while read -r img; do
    # Skip sat_demo directory
    if [[ "$img" == *"sat_demo"* ]]; then
        continue
    fi
    rel_path="${img#$SRC/}"
    dst_path="$DST/$rel_path"
    copy_file "$img" "$dst_path"
done
echo "Copied chapter images"

# Copy Forge example files that might be referenced
find "$SRC/chapters" -type f -name "*.frg" | while read -r frg; do
    # Skip sat_demo directory
    if [[ "$frg" == *"sat_demo"* ]]; then
        continue
    fi
    rel_path="${frg#$SRC/}"
    dst_path="$DST/$rel_path"
    copy_file "$frg" "$dst_path"
done
echo "Copied Forge example files"

# Copy Python files that might be referenced (including sat_demo)
find "$SRC/chapters" -type f -name "*.py" | while read -r py; do
    rel_path="${py#$SRC/}"
    dst_path="$DST/$rel_path"
    copy_file "$py" "$dst_path"
done
echo "Copied Python files"

# Copy JavaScript files (Sterling visualizations)
find "$SRC/chapters" -type f -name "*.js" | while read -r js; do
    rel_path="${js#$SRC/}"
    dst_path="$DST/$rel_path"
    copy_file "$js" "$dst_path"
done
echo "Copied JavaScript files"

# Copy small CNF files from sat_demo (skip large ones: nq50+)
for cnf in "$SRC/chapters/solvers/sat_demo"/nq{3,4,5,6,8,10,20,30}.cnf; do
    if [ -f "$cnf" ]; then
        rel_path="${cnf#$SRC/}"
        dst_path="$DST/$rel_path"
        copy_file "$cnf" "$dst_path"
    fi
done
echo "Copied small CNF files (skipped nq50+, nq100, nq200)"

echo ""
echo -e "${GREEN}Migration complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Install dependencies: pip install -r requirements.txt"
echo "  2. Preview locally: mkdocs serve"
echo "  3. Build: mkdocs build"
echo ""
echo "For versioned deployment with mike:"
echo "  mike deploy 2025"
echo "  mike deploy 2026 latest"
echo "  mike set-default latest"
echo "  mike serve"
