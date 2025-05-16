printf '\033c'
echo "Welcome to the install script"

echo checking for internet connection
ping -c 1 -W 5 8.8.8.8

# Internet Connection
if [ $? -eq 0 ]; then
  echo "Internet connection detected"
else
  echo "No internet connection detected"
  echo "do you want to connect to a wifi network?"
  read answer
  if [[ $answer = y ]] ; then
	  interfaces=(wlan0)
	  for iface in "${interfaces[@]}"; do
  	     	  # Get available networks on the current interface
		  iwctl station $iface scan | grep "ssid " | cut -d ' ' -f2-
	  echo "Enter the ssid you want to connect"
	  read ssid
	  interface="wlan0"
	  read -s -p "Enter Wi-Fi password for '$SSID': " PASSWORD
	  echo

	  # Connect to the network with the password
	  iwctl station $INTERFACE connect "$SSID" key s:"$PASSWORD"

	  # Check connection status (optional)
	  iwctl station $INTERFACE show

	  echo "Connection attempt initiated. Please check 'iwctl station $INTERFACE show' for status."
	  done
  fi
fi

echo checking if you are booted in uefi mode
ls /sys/firmware/efi/efivars/
echo Are booted in uefi? \(long text with uuids\)
read answer

if [[ $answer = y ]] ; then
	echo "Congratulations, going to next step"
else
	echo "You need to run this script in uefi mode"
	exit 1
fi

#part1 installing arch linux
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
lsblk
echo "Enter drive: "
read drive

cfdisk /dev/$drive
echo "Enter linux filesystem Partition: "
lsblk
read partition
mkfs.ext4 /dev/$partition

read -p "Did you also create efi partition? [y/n] " answer
if [[ $answer = y ]] ; then
  lsblk
  echo "Enter EFI partition: "
  read efipartition
  mkfs.vfat -F 32 /dev/$efipartition
fi

mount /dev/$partition /mnt
pacstrap /mnt base base-devel linux linux-firmware grub
genfstab -U /mnt >> /mnt/etc/fstab


sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install_part_2.sh
chmod +x /mnt/arch_install_part_2.sh
arch-chroot /mnt ./arch_install_part_2.sh

exit

#part2

print '\033c'

echo "Welcome to arch linux"
echo "Continue to install HyprInsomnia"

pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub efibootmgr os-prober dosfstools mtools
lsblk
echo "Enter EFI partition: "
read efipartition
mkdir /boot/efi
mount /dev/$efipartition /boot/efi 
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm git vim gedit networkmanager cargo
systemctl enable NetworkManager

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
#echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#echo "%Defaults timestamp_timeout=0" >> /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel -s /bin/bash $username
passwd $username 

echo "Pre-Installation You can Reboot the system now"
ai3_path="/home/$username/arch_install3.sh"
sed '1,/^#part3$/d' `basename $0` > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
echo "Part 3 script has been created at $ai3_path"
echo "After reboot, please log in as $username and run $ai3_path"

#part3
printf '\033c'

echo "Welcome to Custom Installation Script!"

# Configuration variables
AUR_HELPER=""
INSTALL_DISCORD="n"
INSTALL_SPOTIFY="n"
INSTALL_TELEGRAM="n"
INSTALL_BRAVE="n"
INSTALL_WINE="n"
INSTALL_DOTFILES="n"
DOTFILES_URL=""

gather_preferences() {
    echo "Please answer the following questions to customize your installation:"
    echo
    echo "1. AUR Helper Selection:"
    echo "   1) yay (recommended)"
    echo "   2) paru"
    read -p "Enter your choice (1 or 2): " aur_choice
    case $aur_choice in
        1) AUR_HELPER="yay" ;;
        2) AUR_HELPER="paru" ;;
        *) echo "Invalid choice. Defaulting to yay."; AUR_HELPER="yay" ;;
    esac
    echo

    echo "Would you like to install the following applications?"
    read -p "Discord? (y/n): " INSTALL_DISCORD
    read -p "Spotify? (y/n): " INSTALL_SPOTIFY
    read -p "Telegram? (y/n): " INSTALL_TELEGRAM
    read -p "Brave Browser? (y/n): " INSTALL_BRAVE
    read -p "Wine (Windows compatibility layer)? (y/n): " INSTALL_WINE
    echo

    read -p "Would you like to install dotfiles using myd (y/n): " INSTALL_DOTFILES
    if [ "$INSTALL_DOTFILES" = "y" ]; then
        read -p "Enter your dotfiles git repository URL: " DOTFILES_URL
        if [ -z "$DOTFILES_URL" ]; then
            echo "No URL provided, disabling dotfiles installation"
            INSTALL_DOTFILES="n"
        fi
    fi
    echo
}

install_aur_helper() {
    cd /home/$USER
    if [ "$AUR_HELPER" = "yay" ]; then
        git clone https://aur.archlinux.org/yay.git
        cd yay
    else
        git clone https://aur.archlinux.org/paru.git
        cd paru
    fi
    makepkg -si
    cd ..
    rm -rf yay paru 2>/dev/null
}

install_programs() {
    echo "Installing base programs..."
    
    # Enable multilib repository
    echo "Enabling multilib repository..."
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm # Update package database after enabling multilib

    # Audio packages
    echo "Installing audio packages..."
    sudo pacman -Syu --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol pamixer || {
        echo "Error installing audio packages. Please check your internet connection."
        return 1
    }

    # Multilib packages (32-bit support)
    echo "Installing multilib support packages..."
    sudo pacman -Syu --noconfirm \
        lib32-pipewire lib32-pipewire-jack \
        lib32-mesa lib32-vulkan-radeon lib32-vulkan-intel \
        lib32-nvidia-utils lib32-amdvlk || {
        echo "Error installing multilib packages. Please check your internet connection."
        return 1
    }

    # Bluetooth packages
    echo "Installing bluetooth packages..."
    sudo pacman -Syu --noconfirm bluez bluez-utils blueman blueberry || {
        echo "Error installing bluetooth packages. Please check your internet connection."
        return 1
    }

    # Qt6 and portal packages
    echo "Installing Qt6 and portal packages..."
    sudo pacman -Syu --noconfirm \
        qt6-base qt6-wayland qt6-svg qt6-declarative \
        qt6-quickcontrols2 qt6-graphicaleffects \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk \
        xdg-desktop-portal || {
        echo "Error installing Qt6 and portal packages. Please check your internet connection."
        return 1
    }

    # System utilities and base programs
    echo "Installing system utilities and base programs..."
    sudo pacman -Syu --noconfirm \
        noto-fonts noto-fonts-emoji \
        ffmpeg fzf xdotool playerctl \
        dunst zsh git vim \
        wl-clipboard cliphist \
        brightnessctl waybar \
        neofetch swaylock \
        mpc mpv \
        ntfs-3g thunar \
        gedit kitty \
        gnome-calculator \
        gnome-system-monitor \
        gvfs gvfs-mtp \
        xdg-user-dirs \
        network-manager-applet || {
        echo "Error installing system utilities. Please check your internet connection."
        return 1
    }

    # Enable necessary services
    echo "Enabling services..."
    sudo systemctl enable --now bluetooth.service
    sudo systemctl enable --now pipewire.service
    sudo systemctl enable --now pipewire-pulse.service
    sudo systemctl --user enable --now wireplumber.service
    sudo systemctl --user enable --now xdg-desktop-portal-hyprland.service
    sudo systemctl --user enable --now xdg-desktop-portal.service

    # Install selected applications
    local apps_to_install=""
    [ "$INSTALL_DISCORD" = "y" ] && apps_to_install="$apps_to_install discord"
    [ "$INSTALL_SPOTIFY" = "y" ] && apps_to_install="$apps_to_install spotify-launcher"
    [ "$INSTALL_TELEGRAM" = "y" ] && apps_to_install="$apps_to_install telegram-desktop"

    if [ ! -z "$apps_to_install" ]; then
        echo "Installing selected applications..."
        sudo pacman -Syu --noconfirm $apps_to_install || {
            echo "Error installing applications. Please check your internet connection."
            return 1
        }
    fi

    echo "Setting up user groups..."
    sudo usermod -a -G input $USER
    sudo usermod -aG audio $USER
    sudo usermod -aG video $USER
    sudo usermod -aG bluetooth $USER

    echo "Installing AUR packages..."
    if ! command -v $AUR_HELPER &> /dev/null; then
        install_aur_helper
    fi

    local aur_packages="hyprland ruby-fusuma hyprshade jq wofi wlogout swww dolphin"
    [ "$INSTALL_BRAVE" = "y" ] && aur_packages="$aur_packages brave-bin"
    [ "$INSTALL_WINE" = "y" ] && aur_packages="$aur_packages wine"
    [ "$INSTALL_DOTFILES" = "y" ] && aur_packages="$aur_packages myd"

    $AUR_HELPER -Syu $aur_packages || {
        echo "Error installing AUR packages. Please check your internet connection."
        return 1
    }

    # Create XDG user directories
    echo "Setting up user directories..."
    xdg-user-dirs-update

    # Set environment variables for Qt and Wayland
    echo "Setting up environment variables..."
    echo "QT_QPA_PLATFORM=wayland" | sudo tee -a /etc/environment
    echo "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" | sudo tee -a /etc/environment
    echo "XDG_CURRENT_DESKTOP=Hyprland" | sudo tee -a /etc/environment
    echo "XDG_SESSION_TYPE=wayland" | sudo tee -a /etc/environment
    echo "XDG_SESSION_DESKTOP=Hyprland" | sudo tee -a /etc/environment

    return 0
}

setup_directories() {
    cd /home/$USER
    mkdir -p Downloads Documents Pictures Music Projects
}

setup_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

setup_hyprinsomnia() {
    cd /home/$USER/Projects
    if [ ! -d "HyprInsomnia" ]; then
        git clone https://github.com/wraient/HyprInsomnia
    fi
    cd HyprInsomnia
    chmod +x *
    ./config_installer
}

setup_dotfiles() {
    if [ "$INSTALL_DOTFILES" = "y" ] && [ ! -z "$DOTFILES_URL" ]; then
        echo "Installing dotfiles from $DOTFILES_URL using myd..."
        myd install "$DOTFILES_URL" || {
            echo "Error installing dotfiles. Please check the repository URL and your internet connection."
            return 1
        }
    fi
    return 0
}

echo "Please choose an option:"
echo "1. Full installation (recommended for first time)"
echo "2. Reinstall programs only (if previous installation failed)"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        echo "Starting full installation..."
        gather_preferences
        echo "Starting installation with your preferences..."
        echo "AUR Helper: $AUR_HELPER"
        echo "Selected applications:"
        [ "$INSTALL_DISCORD" = "y" ] && echo "- Discord"
        [ "$INSTALL_SPOTIFY" = "y" ] && echo "- Spotify"
        [ "$INSTALL_TELEGRAM" = "y" ] && echo "- Telegram"
        [ "$INSTALL_BRAVE" = "y" ] && echo "- Brave Browser"
        [ "$INSTALL_WINE" = "y" ] && echo "- Wine"
        if [ "$INSTALL_DOTFILES" = "y" ]; then
            echo "- Dotfiles will be installed from: $DOTFILES_URL"
        fi
        echo
        read -p "Press Enter to continue or Ctrl+C to cancel..."

        setup_directories
        if install_programs; then
            setup_zsh
            setup_hyprinsomnia
            if [ "$INSTALL_DOTFILES" = "y" ]; then
                setup_dotfiles
            fi
            echo "Full installation completed successfully!"
        else
            echo "Installation failed. Please run the script again and choose option 2 to retry installing programs."
        fi
        ;;
    2)
        echo "Reinstalling programs only..."
        gather_preferences
        if install_programs; then
            if [ "$INSTALL_DOTFILES" = "y" ]; then
                setup_dotfiles
            fi
            echo "Program installation completed successfully!"
        else
            echo "Program installation failed. Please check your internet connection and try again."
        fi
        ;;
    *)
        echo "Invalid choice. Please run the script again and select 1 or 2."
        exit 1
        ;;
esac

systemctl enable bluetooth
echo "Installation process completed!"

#vencord install
