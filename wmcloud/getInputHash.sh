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

# Output CSV header
echo "File Name,Real Path,File Size (bytes),Creation Date,SHA-256"

# Loop through all files in the specified directory
for file in "$DIR"/*; do
    # Get realpath
    real_path=$(realpath "$file")

    # Get file size
    file_size=$(stat --format="%s" "$real_path")

    # Get file creation date
    creation_date=$(stat --format="%w" "$real_path")

    # If creation date is not available, fall back to last modification time
    if [ "$creation_date" == "-" ]; then
        creation_date=$(stat --format="%y" "$real_path")
    fi

    # Get SHA-256 checksum
    sha256sum=$(sha256sum "$real_path" | awk '{ print $1 }')

    # Output the results in CSV format
    echo "\"$file\",\"$real_path\",$file_size,\"$creation_date\",$sha256sum"

done
