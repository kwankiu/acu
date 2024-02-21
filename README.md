# Arch (ARM) Configuration Utility (experimental)

![alt Arch Rock Configuration Utility](https://i.imgur.com/bccc10d.png)

## What is acu?
- acu is a configuration utility for Arch Linux ARM (Aarch64) 
- acu provides some similar features with [armbian-config](https://github.com/armbian/config) or [raspi-config](https://www.raspberrypi.com/documentation/computers/configuration.html) or [rsetup](https://docs.radxa.com/en/radxa-os/rsetup/rsetup-tool) but for Arch Linux
- acu provides a pacman (and other package manager) wrapper with additional features (such as installing packages from a github release based repo, from URL, compiling and installing packages from source (PKGBUILD), etc.)
- currently with main focus on the Radxa Rock 5 and RK3588

### Note that this configuration utility is work-in-progress.

## Installation

The configuration utility is pre-installed with Arch Linux installed or provided by [archlinux-installer-rock5](https://github.com/kwankiu/archlinux-installer-rock5) (it currently uses `arch-rock-config` but will soon be mirgated to `acu`)

To install `acu`, run the following command :

```
bash <(curl -fsSL https://raw.githubusercontent.com/kwankiu/acu/dev/acu)
```

## Usage

To launch the configuration utility:
```
acu
```
## Optional arguments

```
acu <options/features> <additional-arguments (optional)>
```
### For example
Install a package without confirming:
```
acu install git --noconfirm
```
OR
```
acu -S git --noconfirm
```

Update with dev channel:
```
acu --update=dev
```

### Options

| Options | Additional Arguments | Description |
| ------------- | ------------- | ------------- |
| `-h` or `--help` | N/A | Usage and Infomation of this configuration utility. |
| `-u` or `--update` | `<channel>` | Install latest configuration utility without checking updates. channel options: main, dev. |


### Features

#### System Maintenance
| Features | Additional Arguments | Description |
| ------------- | ------------- | ------------- |
| `upgrade` |  N/A | Check & Perform Selective / Full System Upgrade. |
| `install-kernel` |  `<kernel>` | Re-install / Replace Linux Kernel. kernel options: rkbsp, rkbsp-git, midstream. |
| `flash-bootloader` |  `<bootloader>` | Flash Latest SPI Bootloader. bootloader options: radxa, radxa-debug, edk2-rock5a, edk2-rock5b, armbian. |

#### Manage Packages
| Features | Additional Arguments | Description |
| ------------- | ------------- | ------------- |
| `install` |  `<package>` | Package Manager (Install only), Includes RK3588 Specified and Customized Packages. You can use it like: `arch-rock-config install chromium neofetch git` |
| `downgrade` |  `<package> <index>` | Install / Downgrade any Arch Linux ARM Packages from Archive (alaa). You can use it like: `arch-rock-config downgrade chromium`. By default only 15 archives shown, you may optionally add `<index>` to show more/less.  |

#### Performance & Features
| Features | Additional Arguments | Description |
| ------------- | ------------- | ------------- |
| `soc` |  `<option>` | Manage SoC Settings. options: `performance`, `ondemand`, `powersave` (and `status` for SoC Monitor). |
| `fan` |  `<option>` | Configure PWM Fan-control. options: `install`, `enable`, `disable` and `status`. |

#### User & Localization
| Features | Additional Arguments | Description |
| ------------- | ------------- | ------------- |
| `user` | `<option>` | Add, Remove and Change User Account Settings. options: `add <user>` `remove <user>` `manage <user>` |
| `locale` |  N/A | Generate Locale Settings. options: `list-generated` : print generated locales, `list-available` : print all available locales to generate, `generate <country_code>` : country code to generate locale (en_US) |
| `font` |  N/A | Install Fonts, TTF, Non-English Characters, Special Characters / Emoji. |
| `time` | `<option>` | Change Time Zone, Current Date and Time. options: `set-time-zone <time-zone> or 'sync'` `set-time-date <YYYY-MM-DD HH:MM:SS>` `network-time-zone` `system-time-zone`|
| `keyboard` |  N/A | Change Keyboard Layout. |
| `wifi` |  N/A | Change WiFi Country Settings. |
