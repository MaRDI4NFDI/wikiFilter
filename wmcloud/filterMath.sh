#!/bin/bash

# Define the source directory and destination directory for symbolic links
SOURCE_DIR="/data/project/wdump/links/latest"
OUTPUT_DIR="/data/project/wdump/math"

# Path to the wikiFilter script
WIKI_FILTER_SCRIPT="$HOME/wikiFilter/wikiFilter.py"

# Chunk size: 10 million articles
SPLITSIZE=10000000

# Loop through all the files in /data/project/wdump/links/latest/
for symlink in "$SOURCE_DIR"/*; do
    # Check if it is a symbolic link
    if [ -L "$symlink" ]; then
        # Get the actual path of the symlink
        actual_file=$(readlink "$symlink")

        # Extract the base name of the file before the first dash
        base_filename=$(basename "$actual_file" | cut -d '-' -f 1)

        # Apply the wikiFilter script with the chunk size
        $WIKI_FILTER_SCRIPT -f "$symlink" -s "$SPLITSIZE" -d "$OUTPUT_DIR"

        # Rename the chunk files created by wikiFilter.py
        chunk_count=1  # Start with chunk 1
        for chunkfile in "$OUTPUT_DIR"/*-*.xml.bz2; do
            # Extract the number from the chunk file name
            chunk_number=$(basename "$chunkfile" | cut -d '-' -f 2 | cut -d '.' -f 1)

            # If it's the first chunk, don't add the chunk number
            if [ "$chunk_number" -eq 1 ]; then
                new_filename="$OUTPUT_DIR/$base_filename.xml.bz"
            else
                new_filename="$OUTPUT_DIR/$base_filename-chunk-$chunk_number.xml.bz"
            fi

            # Rename the chunk file
            mv "$chunkfile" "$new_filename"
            echo "Renamed $chunkfile to $new_filename"
        done

        echo "Processed symlink $symlink with wikiFilter.py, renamed output files"
    fi
done
