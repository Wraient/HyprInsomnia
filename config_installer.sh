#!/bin/bash

# Define the base path of your GitHub repo (adjust this to your actual repo path)
git clone https://github.com/wraient/dotfiles --depth 1
REPO_PATH="$(pwd)"

# Change to the repo directory
cd "$REPO_PATH" || exit 1

# Process each directory
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

# Process loose files
if [ -f ".original_path" ]; then
    # Read each line in the .original_path file
    while IFS= read -r line; do
        # Extract the file name and the original path
        FILENAME=$(basename "$line")
        ORIGINAL_PATH="${line/\$USER/$USER}"

        # Check if the file exists in the repository
        if [ -f "$FILENAME" ]; then
            # Create parent directories if they don't exist
            mkdir -p "$(dirname "$ORIGINAL_PATH")"

            # Copy the file to the original path
            cp "$FILENAME" "$ORIGINAL_PATH"

            echo "Copied $FILENAME to $ORIGINAL_PATH."
        else
            echo "File $FILENAME not found in the repository. Skipping."
        fi
    done < ".original_path"

    # Optionally remove the central .original_path file if no longer needed
    # rm ".original_path"
else
    echo "No central .original_path file found. Skipping loose files."
fi

echo "Done!"
