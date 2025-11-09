This folder contains helper files to build a .deb for the Flutter Linux bundle.

Usage:
  From repository root run:
    ./packaging/linux/build_deb.sh

The script will read `build/linux/x64/release/bundle` and create a .deb in `packaging/linux/output`.

Icon support:
- To include an application icon, place a 256x256 (or larger) PNG at
  `packaging/linux/icon.png`. The build script will copy it into the
  hicolor icon theme directory inside the package and set the desktop
  entry Icon to `brightness`.
