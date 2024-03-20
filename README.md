# ACU (A Configuration Utility for Arch Linux ARM)
### Warning: ACU is still experimental. 
### Some feature may not be usable and commands may change without further notices

![alt ACU Screenshot](https://i.imgur.com/0bMi2Lh.png)

## What is acu?

- **Supported Platform**: ACU is a community-built Configuration Utility for Arch Linux ARM (Aarch64). Since most of the commands are the same on Arch Linux ARM and x86_64, this utility can also be used on x86_64, but some features are ARM / SBC specific, therefore it is not fully supported. ACU is currently with main focus on Rockchip RK3588 (Radxa Rock 5B) as this is the primary ARM SBC i am using.

- **Configuration Utility**: ACU provides some similar features with [armbian-config](https://github.com/armbian/config) or [raspi-config](https://www.raspberrypi.com/documentation/computers/configuration.html) or [rsetup](https://docs.radxa.com/en/radxa-os/rsetup/rsetup-tool) but for Arch Linux

- **Packages Management**: ACU act as a package manager helper that gather everything in one place with additional features (such as a menu that allows you to selectively upgrade packages, downgrading a package to a specific version, installing a package from a github release or URL, compiling and installing packages from source (PKGBUILD) like AUR or other Git Repositories, etc.) With ACU, you can do all this in one command.

- **Introducing ACU Apps**: ACU provides an "App Store" like [pi-apps](https://github.com/Botspot/pi-apps) which provides a collection of apps for Arch Linux ARM and ARM Single Board Computers. 

- **System Infomation**: ACU provides system infomation just like [Neofetch](https://github.com/dylanaraps/neofetch) but with ARM support (software like neofetch is capapable, some ARM SoC's CPU and GPU infomation may not be shown properly, ACU has got this covered)

- **Customization**: ACU currently provides a configuration file `config.yaml`, a repositories list `repo.yaml`, and an apps list `apps.yaml` which allows you to customize configurations, add/remove an ACU managed repositories, modify or creating your own apps list for **ACU Apps**, etc. it is also possible to load a configuration file from a path / url using `--loadconfig` and configurate your own `repo.yaml` and `apps.yaml` upstream or locally.

## Sounds cool. How do I Install it?

The configuration utility is pre-installed with Arch Linux installed or provided by [archlinux-installer-rock5](https://github.com/kwankiu/archlinux-installer-rock5) (it currently uses `arch-rock-config` but will soon be mirgated to `acu`)

### Mirgating from `arch-rock-config` to `ACU` :
```
arch-rock-config -u acu
```
To remove `arch-rock-config` itself:
```
arch-rock-config --remove-this
```

OR

### New Install :
```
bash <(curl -fsSL https://raw.githubusercontent.com/kwankiu/acu/0.0.5-dev/acu) -u
```
(Notes: ACU automatically installs the latest version available using the -u command)

## Getting Started
### Quick Start :
To get started, let's add some ACU recommended repositories. 
(Notes: Advanced user can use ACU with their own configurations and repositories.)
```
  acu rem set default 
```

Now let's fetch the repositories and update the apps list.
(Notes: the acu repo currently requires [AGR](https://github.com/hbiyik/agr) and you will be prompted to install the software)
```
acu update
```
(Notes: To make sure the repositories and apps list is up-to-date, you should run `acu update` regularly, ACU will also sync pacman repositories database for you.)

### Updating ACU
To update ACU itself, when there is an update available, there will be an option shows up when you run `acu`. Alternatively, you may also update ACU manually using:
```
acu -u
```
To update to a specific version or channel:
```
acu --update=0.0.5-dev
```

### Removing ACU

To uninstall ACU:
```
acu remove acu
```
If AGR is installed, you may want to remove AGR before removing ACU:
```
acu remove agr
```

## Tips

### Install command
```
acu install <package>
```
is same as
```
acu -S <package>
```
To install a package with a specific package manager / helper
```
acu install <package> --usepm=<pm>
# <pm> options: pacman, agr, git, ghrel.
```

To install a linux kernel (--device is needed for ACU to update extlinux.conf automatically):
```
acu install <linux-package> --device=<tag>
# available tags are rock5, orangepi5 and edge2
``` 
(Notes: refer to [boot-templates](https://github.com/kwankiu/archlinux-installer-rock5/tree/main/boot-templates))

### Remove command
```
acu remove <package>
```
is same as
```
acu -R <package>
```

### Downgrade command
```
acu downgrade <package>
```
is same as
```
acu -D <package>
```

### Remote / Repositories command
List ACU managed repositories
```
acu rem list
```
is same as
```
acu rem show
```

Fetch ACU managed repositories and list all packages
```
acu rem
```
is same as
```
acu rem fetch
```

More detailed documentation will be available on [wiki](https://github.com/kwankiu/acu/wiki)