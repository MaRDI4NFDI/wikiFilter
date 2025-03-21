#!/bin/bash

# Define the source directory and destination directory for symbolic links
SOURCE_DIR="/data/project/wdump/links/latest"
OUTPUT_DIR="/data/project/wdump/math"

# Path to the wikiFilter script
WIKI_FILTER_SCRIPT="~/wikiFilter/wikiFilter.py"

# Loop through all the files in /data/project/wdump/links/latest/
for symlink in "$SOURCE_DIR"/*; do
    # Check if it is a symbolic link
    if [ -L "$symlink" ]; then
        # Apply the wikiFilter script directly to the symbolic link
        python3 "$WIKI_FILTER_SCRIPT" -d "$OUTPUT_DIR" "$symlink"
        echo "Processed symlink $symlink with wikiFilter.py"
    fi
done
