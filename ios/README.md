# EasyRPG buildscripts

## iOS Toolchain and libraries

Only native build supported, no osxcross support!

Specific building requirements for MacOSX:

 - XCode
 - autotools
 - git
 - libtool
 - pkg-config
 - SDL2 (required by autoreconf when patching SDL2 mixer)

Local build process:

Run `0_build_everything.sh` in a terminal
