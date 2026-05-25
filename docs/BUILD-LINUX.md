# Building Hilal Browser on Linux

This is a short addendum to Mozilla's official guide:
https://firefox-source-docs.mozilla.org/setup/linux_build.html

Prerequisites

# 1. Install dependencies

Run the command corresponding to your Linux distribution:

Ubuntu / Debian / Linux Mint

```
sudo apt update
sudo apt install -y git python3 python3-pip curl python3-dev build-essential \
  libgtk-3-dev libdbus-glib-1-dev yasm libasound2-dev libpulse-dev \
  libx11-xcb-dev libxt-dev clang ccache
```


Arch Linux / EndeavourOS / CachyOS

```sudo pacman -Syu --needed base-devel git python curl python-pip gtk3 \
  dbus-glib yasm alsa-lib pulseaudio libxcb libxt clang ccache
```


Fedora / RHEL
```
sudo dnf groupinstall "Development Tools" "C Development Tools and Libraries"
sudo dnf install -y git python3 python3-pip curl gtk3-devel dbus-glib-devel \
  yasm-devel alsa-lib-devel pulseaudio-libs-devel libxcb-devel libXt-devel clang ccache
```

# 2. Fetch Firefox upstream source into ./firefox
```
bash scripts/setup-firefox.sh
```

# 3. Reset worktree and force apply custom patches
```
bash scripts/apply.sh --force
```

# 4. Run the automated build script
```
bash scripts/build-linux.sh
```


Build script parameters

Full build:

```
bash scripts/build-linux.sh
```

Build and run immediately:

```
bash scripts/build-linux.sh run
```

Build and package immediately:

```
bash scripts/build-linux.sh package
```

Where does the built app live?

After a successful build, the Linux binaries are at:

```
firefox/obj-x86_64-pc-linux-gnu/dist/bin/
```

The executable name comes from branding/hilal/configure.sh, which sets MOZ_APP_DISPLAYNAME to Hilal Browser.

Packaging

To produce a redistributable tarball manually:

```
cd firefox && ./mach package
```


The output lands in:

```
firefox/obj-x86_64-pc-linux-gnu/dist/firefox-*.linux-x86_64.*
```

Common issues

mach not found. Make sure you're inside firefox/ when running raw ./mach commands. If you are using scripts/build-linux.sh, run it from the root of the repo.

Out-of-Memory (OOM) crashes. Standard C++/Rust compilation requires massive RAM (~2GB per thread). If your kernel kills the compiler, restrict parallel jobs in your mozconfig:

# Limit to 4 active workers
echo "mk_add_options MOZ_MAKE_FLAGS=-j4" >> firefox/mozconfig


Wayland rendering crashes. On Wayland-native sessions, if ./mach run crashes, force Wayland rendering:

MOZ_ENABLE_WAYLAND=1 ./mach run


Object directory corruptions. If you changed branches or merged upstream code, clear the build cache:

cd firefox && ./mach clobber


Slow builds after force-apply. Running scripts/apply.sh --force resets the tree, which invalidates the compiler's build cache. Expect a slow next build.