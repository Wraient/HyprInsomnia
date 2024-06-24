### This is a configuration uploader from arch linux to github upstream.

# Installation

```
git clone --depth=1 https://github.com/Wraient/HyprInsomnia
```

# Usage

Enter the directories or files you want to upload to github using

`config_upload.sh -e`

this will open a vim instance for you to change HyprInsomnia config

config e.g.

```
/home/wraient/.zshrc
/home/wraient/.local/bin
/home/wraient/.config/hypr
/home/wraient/.config/fusuma
/home/wraient/.config/rofi
/home/wraient/.config/waybar
/home/wraient/.config/HyprInsomnia
/home/wraient/.config/kitty
/home/wraient/.config/jerry
/home/wraient/.config/dunst
/home/wraient/.config/spicetify
/home/wraient/.gitignore
/home/wraient/.config/mov-cli
/home/wraient/Pictures/wall
```

Using absolute path is recommended.

# Working

### Copying files to /home/$USER/.hidden/dotfiles
1. Delete everything inside the dotfiles directory (rm -rf'ed)
2. Copy all the files and folders specified in /home/$USER/.config/hyprinsomnia/files.conf to dotfiles directory
3. Copy the path of the file into .original_path (default) in dotfiles (all loose files have the same .original_path file)
4. Copy the path of the directories into respective folders in .original_path (default)
5. Change the name of the user to "$USER" in all .original_path file

### Uploading dotfiles to GitHub
1. Upload /home/$USER/.hidden/dotfiles to specified github repo

### Installing config
1. Clone dotfiles GitHub repo
2. Iterate through each folder and copy the iterated folder to respective path specified in .original_path
3. copy the files in dotfiles/.original_path to their specified location
