#!/bin/bash

# Define terminal color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
DEBUG='\033[0;37m'
NC='\033[0m' # No Color

# Echo with colors
colorecho() {
    color="$1"
    text="$2"
    [ -n "$no_warning" ] && [ "$color" = "$YELLOW" ] || [ "$color" = "$DEBUG" ] && [ -z "$debug_log" ] || echo -e "${color}${text}${NC}"
}

# for detecting system architecture
system_arch=$(uname -m)

# Disable option picker
no_confirm=1

################################################################
# Update boot config (extlinux/grub/systemd-boot)
update_boot_config() {

    # Make sure argument isnt treated as pkgname
    if [[ "$1" != "-"* ]]; then
        local pkgname=$1
    fi

    # If not specified then look for the mainline stable kernel
    if [ -z "$pkgname" ]; then
        colorecho "$THEME" "INFO  $NC | pkgbase is not specified, looking for installed kernel ..."
        # Find all kernel packages
        local kernels=($(pacman -Q | grep 'linux' | awk '{print $1}'))
        local valid_kernels=()
        for kernel in "${kernels[@]}"; do
            if sudo pacman -Ql "$kernel" | grep -q 'pkgbase\|Image'; then
                valid_kernels+=("$kernel")
            fi
        done
        # Determine the valid kernels
        if [ ${#valid_kernels[@]} -eq 1 ]; then
            pkgname="${valid_kernels[0]}"
            colorecho "$THEME" "INFO  $NC | Automatically detected kernel: $pkgname ..."
        elif [ ${#valid_kernels[@]} -gt 1 ]; then
            if [ -z "$no_confirm" ]; then
                title "Multiple valid kernels found:"
                select_option "${valid_kernels[@]}"
                choice=$?
                pkgname="${valid_kernels[choice]}"
                colorecho "$THEME" "INFO  $NC | Selected kernel: $pkgname ..."                
            else
                pkgname="${valid_kernels[0]}"
                colorecho "$THEME" "INFO  $NC | Multiple valid kernels found, using the first: $pkgname ..."
            fi
        else
            colorecho "$RED" "ERROR $NC | No valid kernel packages found. Please specify a kernel."
            return 1
        fi
    fi

    # Make sure package is installed and get kernel infomation
    if sudo pacman -Q "$pkgname" > /dev/null 2>&1 ; then
        local pkgbase="$(sudo pacman -Ql "$pkgname" | grep pkgbase | awk '{print $2}')"
        local kimage="$(sudo pacman -Ql "$pkgname" | grep Image | awk '{print $2}')"
        if [ -n "$pkgbase" ]; then
            pkgbase="$(cat $pkgbase)"
        elif [ -n "$kimage" ]; then
            pkgbase="linux"
        else
            colorecho "$RED" "ERROR $NC | Boot Config can not be updated. (Can not determine pkgbase, Package $pkgname may not be a kernel)"
            return 1
        fi
        colorecho "$THEME" "INFO  $NC | Updating boot config for $pkgbase ..."
    else
        colorecho "$RED" "ERROR $NC | Boot Config can not be updated. (Package $pkgname is not installed)"
        return 1
    fi

    # EFI System
    if sudo ls /boot/EFI/BOOT | grep -q BOOT.*.EFI; then
        colorecho "$THEME" "INFO  $NC | UEFI System detected."
        # Detect EFI Bootloader
        if sudo test -d /boot/grub && command -v grub-install &> /dev/null; then
            # Grub
            colorecho "$THEME" "INFO  $NC | Updating grub.cfg ..."
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        elif sudo test -f /boot/EFI/systemd/systemd-boot*.efi; then
            # Systemd-boot
            colorecho "$THEME" "INFO  $NC | Updating systemd-boot ..."
            sudo bootctl update
            colorecho "$THEME" "INFO  $NC | You may need to update the configurations at /boot/loader/entries/ ..."
        else
            # Unsupported
            colorecho "$RED" "ERROR $NC | Boot Config can not be updated. (Unsupported bootloader method)"
            return 1
        fi
        # DT Overlay Support
        # Feature need to be enabled in BIOS, support platforms like edk2-rk3588
        if [ -n "$add_dtoverlay" ]; then
            local target_dtbo=$(basename $add_dtoverlay)
            local found_dtbo
            local dtbo
            if found_dtbo=$(sudo find /boot/dtbs/${pkgbase} -type f -name $target_dtbo -exec dirname {} \; 2>/dev/null | head -n 1) && sudo test -f ${found_dtbo}/${target_dtbo}; then
                    dtbo="${found_dtbo}/${target_dtbo}"
            elif found_dtbo=$(sudo find /boot/dtbs -type f -name $target_dtbo -exec dirname {} \; 2>/dev/null | head -n 1) && sudo test -f ${found_dtbo}/${target_dtbo}; then
                    dtbo="${found_dtbo}/${target_dtbo}"
            elif sudo test -e "${overlaylist[i]}"; then
                    dtbo="${overlaylist[i]}"
            fi
            # Copy the found overlay to /boot/dtb/base/overlay
            if [ -n "$dtbo" ]; then
                sudo mkdir -p /boot/dtb/base/overlay
                sudo cp $dtbo /boot/dtb/base/overlay/
                colorecho "$THEME" "INFO  $NC | Overlay copied to /boot/dtb/base/overlay"
                colorecho "$THEME" "INFO  $NC | Make sure your UEFI firmware is configured to support DTB Overlays"
            else
                colorecho "$RED" "ERROR $NC | Unable to add the following DT Overlay: $target_dtbo (file not found)"
            fi
        fi
    # Update extlinux from booted config
    elif sudo test -f "/boot/extlinux/extlinux.conf"; then
        colorecho "$THEME" "INFO  $NC | Creating a backup of extlinux.conf at extlinux.conf.bak ..."
        sudo rm -rf /boot/extlinux/extlinux.conf.bak
        sudo mv /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.bak
        colorecho "$THEME" "INFO  $NC | Generating new extlinux.conf ..."
        # Kernel
        echo "# This extlinux.conf is auto-generated by ACU" | sudo tee "/boot/extlinux/extlinux.conf" >/dev/null
        echo " " | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        echo "label ${pkgbase}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        if [ -n "$kimage" ]; then
            echo "    kernel /Image" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        else
            echo "    kernel /vmlinuz-${pkgbase}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        fi
        echo "    initrd /initramfs-${pkgbase}.img" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        # DTB dir
        if sudo test -d "/boot/dtbs/${pkgbase}"; then
            echo "    devicetreedir /dtbs/${pkgbase}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        else
            # Mainline kernel
            echo "    devicetreedir /dtbs" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        fi
        # DTB file (ftd)
        local ftdline
        if ftdline="$(cat /boot/extlinux/extlinux.conf.bak | grep -m 1 'ftd ')"; then
            # Add dtb fdt file
            echo "${ftdline}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        fi
        # Overlays
        local overlaysline="$(cat /boot/extlinux/extlinux.conf.bak | grep -m 1 'fdtoverlays ')"
        if [ -n "$add_dtoverlay" ]; then
            if [ -n "$overlaysline" ]; then
                overlaysline+=" $add_dtoverlay"
            else
                overlaysline="fdtoverlays $add_dtoverlay"
            fi
        fi
        if [ -n "$overlaysline" ]; then
            local overlaylist=($overlaysline)
            local i
            local dtbolist
            for ((i = 1; i < ${#overlaylist[@]}; i++)); do
                local target_dtbo=$(basename ${overlaylist[i]})
                local found_dtbo
                if found_dtbo=$(sudo find /boot/dtbs/${pkgbase} -type f -name $target_dtbo -exec dirname {} \; 2>/dev/null | head -n 1) && sudo test -f ${found_dtbo}/${target_dtbo}; then
                    dtbolist+=("${found_dtbo}/${target_dtbo}")
                elif found_dtbo=$(sudo find /boot/dtbs -type f -name $target_dtbo -exec dirname {} \; 2>/dev/null | head -n 1) && sudo test -f ${found_dtbo}/${target_dtbo}; then
                    dtbolist+=("${found_dtbo}/${target_dtbo}")
                elif sudo test -e "${overlaylist[i]}"; then
                    dtbolist+=("${overlaylist[i]}")
                else
                    colorecho "$RED" "ERROR $NC | Unable to add the following DT Overlay: $target_dtbo (file not found)"
                fi
            done
            if [ -n "$dtbolist" ]; then
                echo "    fdtoverlays ${dtbolist[@]}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
            fi
        fi
        # Append (cmdline)
        local appendline
        if appendline="$(cat /boot/extlinux/extlinux.conf.bak | grep -m 1 'append ')"; then
            # Use cmdline from the backup extlinux.conf
            echo "${appendline}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        elif sudo test -f "/proc/cmdline"; then
            # Use cmdline from booted cmdline
            local cmdline="$(cat /proc/cmdline)"
            echo "    append   ${cmdline}" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        else
            # Get rootfs partition from the current mount point "/"
            rootfs_partition=$(mount | grep "on / " | awk '{print $1}')
            # Find the UUIDs of the root partition
            root_uuid=$(sudo blkid $rootfs_partition | awk '{print $2}' | tr -d '"')
            colorecho "$DEBUG" "Root partition UUID: $root_uuid"
            # Use default cmdline
            echo "    append   root=UUID=${root_uuid} rw quiet splash" | sudo tee -a "/boot/extlinux/extlinux.conf" >/dev/null
        fi

        # Check if /boot is mounted as a partition or directory
        if mountpoint -q /boot; then
            colorecho "$DEBUG" "INFO  $NC | /boot is mounted as a partition"
        else
            colorecho "$DEBUG" "INFO  $NC | /boot is mounted as a directory"
            colorecho "$THEME" "INFO  $NC | Updating paths for extlinux.conf ..."
            sudo sed -i "s| /vmlinuz| /boot/vmlinuz|" /boot/extlinux/extlinux.conf
            sudo sed -i "s| /Image| /boot/Image|" /boot/extlinux/extlinux.conf
            sudo sed -i "s| /initramfs| /boot/initramfs|" /boot/extlinux/extlinux.conf
            sudo sed -i "s| /initrd| /boot/initrd|" /boot/extlinux/extlinux.conf
            sudo sed -i "s| /dtbs| /boot/dtbs|" /boot/extlinux/extlinux.conf
            sudo sed -i "s| /dtbo| /boot/dtbo|" /boot/extlinux/extlinux.conf
        fi
    else
        colorecho "$RED" "ERROR  $NC | Boot Config can not be updated. (Unable to detect boot firmware)"
        return 1
    fi
}

update_boot_config "$1"