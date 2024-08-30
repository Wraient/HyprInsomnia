#!/bin/bash

# Define configuration file path
config_file="/home/$USER/.config/HyprInsomnia/files.conf"

# Define destination folder
destination_folder="/home/$USER/.hidden/dotfiles"

original_file_filename=".original_path"  # Name of the file to create
github_username="wraient"
repo_url="github.com/wraient/dotfiles.git"

GIT_AUTH_KEY=$(cat /home/$USER/.auth/github_wraient)
dotfile_path="/home/$USER/.hidden/dotfiles"

tmp_dir=$(mktemp -d /tmp/copy_files.XXXXXXXXXX)
mv $destination_folder/.git $tmp_dir
rm -rf $destination_folder/*
rm -rf $destination_folder/.*
mv $tmp_dir/.git $destination_folder

# Function to create a file with original path information
function create_path_info_file() {
    destination_path="$1"  # Capture destination path from function argument
    source_path="$2"    # Capture source path from function argument
    # Create the file with the source path
    username=$(whoami)

    # Replace the username with the literal string '$USER' if it exists in the source path
    modified_source_path=$(echo "$source_path" | sed "s|$username|\\\$USER|g")

    # Create the file with the modified source path
    echo "$modified_source_path" > "$destination_path/$original_file_filename"
    echo Created original file at $destination_path/$original_file_filename

}

# Function to copy files with path information
function copy_files() {

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
            username=$(whoami)
            # Replace the username with the literal string '$USER' if it exists in the source path
            modified_source_path=$(echo "$source_path" | sed "s|$username|\\\$USER|g")
            echo $modified_source_path >> $destination_folder/$original_file_filename
            cp -p -r "$source_path" "$destination_folder"
        fi

        # Extract filename only (avoid nested folders)
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
}

# Check if edit mode is enabled (-e flag)
if [ "$1" == "-e" ]; then
    echo "Edit mode enabled."
    vi $HOME/.config/HyprInsomnia/files.conf
    echo "Config Updated."
    exit
fi

# Ensure Git binary is available
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed."
    exit 1
fi

# Check if the destination folder (.dotfiles) exists (optional)
if [ ! -d $dotfile_path ]; then
    echo "Initializing local Git repository..."
    mkdir -p $dotfile_path
    cd $dotfile_path
    git init
fi

echo "Copying config files to HyprInsomnia"
copy_files &> /dev/null

cd $dotfile_path

# Git operations (assuming SSH key authentication)
git config --global user.email "$USER@$HOST.com"
git config --global user.name "$USER"

# Function to unset the key after use (security best practice)
function unset_key {
    unset GIT_SSH_KEY
}

# Trap to ensure key unsetting even if script exits prematurely
trap unset_key EXIT

# Add all tracked files (if any) and stage them for commit
git add . &> /dev/null  # Suppress output for clean execution

# Commit changes with a descriptive message (replace with your message)
git commit -m "Automatic dotfiles backup - $(date)"
# Push changes to the remote repository using SSH key (avoid storing key directly)
git push https://$github_username:$GIT_AUTH_KEY@$repo_url  # Use with caution (force push)

# Unset the temporary key environment variable
unset_key

echo "Dotfiles committed and pushed to remote repository."
