#!/bin/bash

# Define the source directory and destination directory
SOURCE_DIR="/public/dumps/public"
DEST_DIR="/data/project/wdump/links/latest"

# Loop through all subfolders in /public/dumps/public/
for subfolder in "$SOURCE_DIR"/*/; do
    # Extract the name of the subfolder (it will be used for the filename pattern)
    folder_name=$(basename "$subfolder")

    # Define the path to the "latest" subfolder
    latest_subfolder="$subfolder/latest"

    # Check if the "latest" subfolder exists
    if [ -d "$latest_subfolder" ]; then
        # Define the file name based on the subfolder name
        file_name="$folder_name-latest-pages-articles-multistream.xml.bz2"
        
        # Check if the file exists and is a symbolic link
        if [ -L "$latest_subfolder/$file_name" ]; then
            # Create a symbolic link in the destination directory
            ln -s "$latest_subfolder/$file_name" "$DEST_DIR/$file_name"
            echo "Created symlink for $file_name"
        else
            echo "No symbolic link found for $file_name in $latest_subfolder"
        fi
    else
        echo "No 'latest' folder found in $subfolder"
    fi
done
