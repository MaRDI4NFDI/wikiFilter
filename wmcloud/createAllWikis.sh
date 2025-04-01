#!/bin/bash

# Default directory if no argument is provided
DEFAULT_DIR="/data/project/wdump/links/latest/"

# Use the provided directory or fallback to default
DIR="${1:-$DEFAULT_DIR}"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo "Directory $DIR does not exist."
    exit 1
fi

# Loop through all files in the specified directory
for lang in "$DIR"/*; do
	echo "processing wiki $lang"
	./scripts/createWiki $lang 2>&1 > $lang.log || echo "Error importing $lang"
done
