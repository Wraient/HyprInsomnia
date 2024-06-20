#!/bin/bash

# Define the base path of your GitHub repo (adjust this to your actual repo path)
REPO_PATH="/path/to/your/github/repo"

# Change to the repo directory
cd "$REPO_PATH" || exit 1

# Iterate through each directory in the repo
for dir in */ ; do
    # Check if .original_path file exists
    if [ -f "${dir}.original_path" ]; then
        # Read the original path from the .original_path file
        ORIGINAL_PATH=$(<"${dir}.original_path")

        # Replace $USER with the actual username
        ORIGINAL_PATH="${ORIGINAL_PATH/\$USER/$USER}"

        # Create parent directories if they don't exist
        mkdir -p "$(dirname "$ORIGINAL_PATH")"

        # Copy the directory to the original path
        cp -r "$dir" "$(dirname "$ORIGINAL_PATH")"

        # Remove the .original_path file
        rm "${dir}.original_path"

        echo "Copied $dir to $ORIGINAL_PATH and removed .original_path file."
    else
        echo "No .original_path file found in $dir. Skipping."
    fi
done

echo "Done!"
