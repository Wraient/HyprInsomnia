
printf '\033c'

echo "Welcome to Custom Installation Script!"

echo "Enter your username"
read username
su $username
cd
#sudo -u $username git clone https://aur.archlinux.org/yay.git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd
mkdir Downloads Documents Pictures Music Projects
sudo pacman -Syu --noconfirm zsh noto-fonts noto-fonts-emoji ffmpeg fzf xdotool playerctl dunst pamixer zsh git vim wl-clipboard cliphist brightnessctl pavucontrol waybar bluez-utils blueman neofetch swaylock mpc mpv ntfs-3g thunar swaylock gedit kitty
systemctl enable bluetooth
echo "Installing applications"
sudo pacman -Syu --noconfirm discord spotify-launcher telegram-desktop
sudo usermod -a -G input $USER
yay -Syu hyprland ruby-fusuma hyprshade jq wofi wlogout swww dolphin brave-bin wine
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cd Projects
git clone https://github.com/wraient/HyprInsomnia
chmod +x *
./config_installer

#vencord install

