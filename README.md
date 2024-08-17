# ACU (A Configuration Utility for Arch Linux ARM)
### Warning: ACU is still experimental. 

![alt ACU Screenshot](https://i.imgur.com/DyaNIfv.png)

## What is acu?

- **Supported Platform**:  ACU is a community-built tool designed for managing configurations and packages on Arch Linux ARM (Aarch64). While primarily tailored for ARM architectures, it can be used on x86_64 platforms as well, although with limitations due to ARM/SBC-specific features. However, it is important to note that ACU is not fully supported on x86_64 platforms. Currently, ACU is optimized for the Rockchip RK3588 (Radxa Rock 5B), serving as a comprehensive utility for ARM Single Board Computers (SBCs).

- **Configuration Utility**: ACU offers functionalities akin to popular configuration tools such as [armbian-config](https://github.com/armbian/config) or [raspi-config](https://www.raspberrypi.com/documentation/computers/configuration.html) or [rsetup](https://docs.radxa.com/en/radxa-os/rsetup/rsetup-tool) but for Arch Linux.

- **Packages Management**: Serving as a package manager helper, ACU consolidates various package management tasks into a single, intuitive interface. It streamlines processes like selective package upgrades, downgrading to specific versions, installing packages from GitHub releases or URLs, as well as compiling and installing packages from source (PKGBUILD), including those from AUR or other Git repositories.

- **Introducing ACU Apps**: ACU introduces an "App Store" like [pi-apps](https://github.com/Botspot/pi-apps), offering a curated collection of applications for Arch Linux ARM and ARM Single Board Computers (SBCs).

- **System Infomation**: ACU provides system information akin to [Neofetch](https://github.com/dylanaraps/neofetch) but with enhanced ARM support. While standard system information tools may struggle with ARM SoC details, ACU ensures comprehensive reporting.

- **Customization**: 
ACU facilitates extensive customization through configuration files like `config.yaml`, `repo.yaml`, and `apps.yaml` (in `~/.acu/config`). These files empower users to tailor configurations, manage repositories, and creating your own or modifying app lists for ACU Apps. Moreover, users can load configurations from local paths or URLs using the `--loadconfig` option, allowing for seamless customization upstream or locally.

## Sounds cool. How do I Install it?

The configuration utility is pre-installed with Arch Linux installed and provided by this [archlinux-installer](https://github.com/kwankiu/archlinux-installer)

### New Install :
```
bash <(curl -fsSL https://raw.githubusercontent.com/kwankiu/acu/main/acu) -u
```
(Notes: ACU automatically installs the latest version available using the -u command)

## Tips

### Updating repositories database
Notes: To make sure the repositories and apps list is up-to-date, you should run `acu update` regularly, ACU will also sync pacman repositories database for you.

```
acu update
```

### Updating ACU
To update ACU itself, when there is an update available, there will be an option shows up when you run `acu`. Alternatively, you may also update ACU manually using:
```
acu -u
```
To update to a specific version or channel:
```
acu --update=main
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

### Install command
To install a package:
```
acu install <package>
```
is same as
```
acu -S <package>
```
To install a package with a specific package manager / helper:
```
acu install <package> --usepm=<pm>
# <pm> options: pacman, agr, git, ghrel.
```
To Install a new kernel:

```
acu install <package>
```

Install a package from source (git repository):
1. Add a repository:
```
acu rem set <repo_name> <repo_url> <repo_type_(optional)> <gpg_key_(optional and for pacman only)>
```
2. Update / fetch the repository database:
```
acu update
```
3. Install a package:
```
acu install <package>
```

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

## Contributing

Contributions to ACU are welcome! Whether you're interested in fixing bugs, adding features, or improving documentation, your contributions help enhance the utility for the community. Feel free to submit pull requests (PRs) with your changes.

## Support

For assistance, bug reports, or feature requests, please [open a Discussion](https://github.com/kwankiu/acu/discussions) on the ACU GitHub repository. Our community is here to help! Discussions are preferred for general inquiries, feature requests, or broader discussions. However, if you encounter a bug or have a specific issue, feel free to [open an issue](https://github.com/kwankiu/acu/issues).

For real-time discussions about ACU, you can also join our Discord server [here](https://discord.gg/yY3F9b7hSK).

## License

ACU is licensed under the GPL v3 License, granting users the freedom to use, modify, and distribute the software.
