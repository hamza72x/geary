Building and Installing Geary on Arch Linux
============================================

This guide provides step-by-step instructions for building and installing Geary on Arch Linux.

Prerequisites
-------------

Before building Geary, you need to install the required dependencies. Run the following command to install all necessary packages:

```bash
sudo pacman -S --needed base-devel meson ninja vala gtk3 webkit2gtk-4.1 \
    sqlite glib2 gmime3 gnome-online-accounts enchant gspell gsound \
    libgee folks libpeas libsecret json-glib libhandy iso-codes \
    libstemmer libunwind libxml2 libytnef desktop-file-utils itstool \
    gettext libicu gcr-4
```

Optional dependencies for additional features:

```bash
# For building API documentation
sudo pacman -S valadoc

# For Ubuntu Messaging Menu integration (via AUR)
yay -S libmessaging-menu
```

SQLite Requirements
-------------------

Geary requires SQLite to be built with FTS3 and FTS5 support. The version provided by Arch Linux's official repositories already includes this support, so no additional configuration is needed.

Building Geary
--------------

1. Clone the repository (if you haven't already):

   ```bash
   git clone https://gitlab.gnome.org/GNOME/geary.git
   cd geary
   ```

2. Configure the build with the release profile:

   ```bash
   meson setup build --prefix=/usr --buildtype=release -Dprofile=release
   ```

   Build profile options:
   - `release`: Production build (required for packaging)
   - `development`: Development build with different branding
   - `beta`: Beta testing build

3. Compile the project:

   ```bash
   ninja -C build
   ```

4. (Optional) Run tests to verify the build:

   ```bash
   meson test -C build
   ```

Installing Geary
----------------

After a successful build, install Geary system-wide:

```bash
sudo ninja -C build install
```

This will install Geary to `/usr/local` by default. To change the installation prefix, use the `--prefix` option during the configuration step.

Running Geary
-------------

After installation, you can run Geary in several ways:

1. From the application menu (requires full installation)
2. From the terminal:

   ```bash
   geary
   ```

3. Or run directly from the build directory without installing:

   ```bash
   ./build/src/geary
   ```

   Note: Running from the build directory has limited desktop integration.

Build Configuration Options
----------------------------

You can customize the build with various Meson options:

```bash
# List all available options
meson configure build

# Example: Disable libunwind support
meson setup build -Dlibunwind=disabled

# Example: Disable TNEF support
meson setup build -Dtnef=disabled

# Reconfigure an existing build
meson configure build -Doption=value
```

Uninstalling Geary
------------------

To uninstall Geary:

```bash
sudo ninja -C build uninstall
```

Building an Arch Package
-------------------------

For a proper Arch Linux installation, you can create a PKGBUILD:

1. Create a `PKGBUILD` file in a new directory:

   ```bash
   mkdir geary-pkg
   cd geary-pkg
   ```

2. Create a minimal PKGBUILD:

   ```bash
   cat > PKGBUILD << 'EOF'
   # Maintainer: Your Name <your.email@example.com>
   pkgname=geary-git
   pkgver=46.0
   pkgrel=1
   pkgdesc="Email application built around conversations for the GNOME desktop"
   arch=('x86_64')
   url="https://wiki.gnome.org/Apps/Geary"
   license=('LGPL-2.1-or-later')
   depends=('gtk3' 'webkit2gtk-4.1' 'sqlite' 'glib2' 'gmime3' 
            'gnome-online-accounts' 'enchant' 'gspell' 'gsound' 
            'libgee' 'folks' 'libpeas' 'libsecret' 'json-glib' 
            'libhandy' 'iso-codes' 'libstemmer' 'libunwind' 
            'libxml2' 'libytnef' 'libicu' 'gcr-4')
   makedepends=('meson' 'ninja' 'vala' 'desktop-file-utils' 'itstool' 'gettext')
   source=("git+https://gitlab.gnome.org/GNOME/geary.git")
   sha256sums=('SKIP')

   build() {
     cd geary
     meson setup build --prefix=/usr --buildtype=release -Dprofile=release
     ninja -C build
   }

   check() {
     cd geary
     meson test -C build || true
   }

   package() {
     cd geary
     DESTDIR="$pkgdir" ninja -C build install
   }
   EOF
   ```

3. Build and install the package:

   ```bash
   makepkg -si
   ```

Troubleshooting
---------------

### Missing Dependencies

If you encounter dependency errors during build:

```bash
# Update your system
sudo pacman -Syu

# Check for missing packages
meson setup build --reconfigure
```

### SQLite FTS Support Errors

If you see errors about SQLite FTS3 or FTS5 support:

```bash
# Reinstall SQLite
sudo pacman -S --force sqlite
```

### Vala Compiler Errors

Ensure you have the minimum required Vala version (0.56+):

```bash
vala --version
```

If your version is older, update your system or install a newer version from AUR.

Getting Help
------------

- Geary Wiki: https://gitlab.gnome.org/GNOME/geary/-/wikis
- GNOME Discourse (geary tag): https://discourse.gnome.org/tags/c/applications/7/geary
- Matrix Channel: #geary:gnome.org
- Report Issues: https://gitlab.gnome.org/GNOME/geary/-/issues

---
Copyright © 2026
