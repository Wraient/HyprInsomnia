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

cfdisk $drive
lsblk
echo "Enter linux filesystem Partition: "
read partition
mkfs.ext4 $partition

read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]] ; then
  lsblk
  echo "Enter EFI partition: "
  read efipartition
  mkfs.vfat -F 32 $efipartition
fi

mount $partition /mnt
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
mount $efipartition /boot/efi 
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm git vim zsh gedit networkmanager
systemctl enable NetworkManager

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo "%Defaults timestamp_timeout=0" >> /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username 

echo "Pre-Installation You can Reboot the system now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username

#part3
printf '\033c'

echo "Welcome to Custom Installation Script!"
cd $HOME
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd
mkdir Downloads Documents Pictures Music Projects
sudo pacman -Syu --noconfirm noto-fonts noto-fonts-emoji ffmpeg fzf ohmyzsh xdotool playerctl dunst pamixer zsh git vim wl-clipboard cliphist brightnessctl pavucontrol waybar bluez-utils blueman neofetch swaylock mpc mpv ntfs-3g thunar swaylock gedit kitty
systemctl enable bluetooth
echo "Installing applications"
sudo pacman -Syu --noconfirm discord spotify-launcher telegram-desktop
sudo usermod -a -G input $USER
paru -Syu hyprland fusuma hyprshade jq wofi wlogout swww dolphin brave-bin wine


#vencord install

