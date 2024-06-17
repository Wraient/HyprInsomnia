#!/bin/bash

# Define configuration file path
config_file="/home/$USER/.config/HyprInsomnia/files.conf"

# Define destination folder
destination_folder="/home/$USER/.hidden/dotfiles"

original_file_filename=".original_path"  # Name of the file to create

tmp_dir=$(mktemp -d /tmp/copy_files.XXXXXXXXXX)
mv $destination_folder/.git $tmp_dir
rm -rf $destination_folder/*
rm -rf $destination_folder/.*
mv $tmp_dir/.git $destination_folder

# Function to create a file with original path information
function create_path_info_file() {
  destination_path="$1"  # Capture destination path from function argument
  source_path="$2"       # Capture source path from function argument
  # Create the file with the source path
  echo "$source_path" > "$destination_path/$original_file_filename"
}


# Check if configuration file exists
if [ ! -f "$config_file" ]; then
  echo "Error: Configuration file '$config_file' not found."
  exit 1
fi

# Ensure destination folder exists
if [ ! -d "$destination_folder" ]; then
  mkdir -p "$destination_folder"
fi

# Loop through each line in the configuration file
while IFS= read -r source_path; do
  # Skip empty lines and comments
  if [[ -z "$source_path" || "$source_path" =~ ^# ]]; then
    continue
  fi

  # Check if source path exists
  if [ ! -e "$source_path" ]; then
    echo "Warning: Skipping non-existent file: $source_path"
    continue
  fi

  # Check if it is folder
  if [ -f "$source_path" ]; then
  	echo $source_path >> $destination_folder/$original_file_filename
	cp -p -r "$source_path" "$destination_folder"
  fi



  # Extract filename and destination path
  filename=$(basename "$source_path")
  destination_path="$destination_folder/$filename"

  # Copy the file with full paths
  if [ -d "$source_path" ]; then
	  echo $source_path
	  cp -r "$source_path/" "$destination_path"
  fi
  # Create the file with original path information
  create_path_info_file "$destination_path" "$source_path"

  echo "Copied: $source_path -> $destination_path (with path info)"
done < "$config_file"

echo "All files copied successfully (with original path information)."

