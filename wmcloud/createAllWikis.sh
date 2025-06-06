#!/bin/bash

# Default directory if no argument is provided
DEFAULT_DIR="/wdump/"

# Use the provided directory or fallback to default
DIR="${1:-$DEFAULT_DIR}"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo "Directory $DIR does not exist."
    exit 1
fi

DOP=4
(
# Loop through all files in the specified directory
for lang in "$DIR"/*; do
        [[ -d $lang ]] && continue
        ((i=i%DOP)); ((i++==0)) && wait -n
        echo "processing wiki $lang"
        filename="${lang##*/}" 
        (./createWiki $lang &> ./log/$filename.log || echo "Error importing $lang")&
done
)
