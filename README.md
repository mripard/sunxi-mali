# Mali support for Allwinner / sunXi platform for mainline Linux

Here is the driver needed in order to support ARM's Mali GPU found on the Allwinner
SoC, using a mainline (ie. Torvalds') kernel.

## Adding the Mali to your Device Tree

If that isn't already the case, you'll need to edit your Device Tree file to
add a node following the [Device Tree binding](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/devicetree/bindings/gpu/arm,mali-utgard.txt)

Don't forget to submit your change afterward to the Linux kernel mailing list..

## Building the kernel module

In order to build the kernel module, you'll need a functional DRM driver. If
you have that already, you'll need the options `CONFIG_CMA` and `CONFIG_DMA_CMA`
enabled in your kernel configuration.

Then, you can compile the module using the following commands:

```
git clone https://github.com/mripard/sunxi-mali.git
cd sunxi-mali
export CROSS_COMPILE=$TOOLCHAIN_PREFIX
export KDIR=$KERNEL_BUILD_DIR
export INSTALL_MOD_PATH=$TARGET_DIR
./build.sh -r r6p2 -b
./build.sh -r r6p2 -i
```

It should install the mali.ko Linux kernel module into the target filesystem,
and the module should be loaded automatically. If it isn't, modprobe will help.

Module is compiled using parallel build by default.
To override jobs number, use -j option as follows:

```
./build.sh -r r6p2 -j 8 -b
```
Where 8 is the number of simultaneous jobs.

## Installing the user-space components

Once the driver is compiled and loaded, you'll need to integrate the OpenGL ES
implementation.

In order to do that, you'll need to do the following commands (assuming you
want the r6p2 fbdev version over the X11-dma-buf one).

```
git clone https://github.com/free-electrons/mali-blobs.git
cd mali-blobs
cp -a r6p2/arm/fbdev/lib* $TARGET_DIR/usr/lib
```

## fbdev quirks

The fbdev variants are meant to deal with applications using the legacy fbdev
interface. The most widely used example would be [Qt](https://www.qt.io/). In
such a case, you'll need to do a few more things in order to have a working
setup.

The Mali blob uses framebuffer panning to implement multiple buffering.
Therefore, the kernel needs to allocate buffers at least twice the size (for
double buffering) of the actual resolution, which it doesn't by default. For
you to change that, you'll need to change either the
`CONFIG_DRM_FBDEV_OVERALLOC` option or the `drm_kms_helper.drm_fbdev_overalloc`
parameter to 100 times the number of simultaneous buffers you want to use (so
200 for double buffering, 300 for triple buffering, etc.).

To avoid screen tearing, set the `FRONTBUFFER_LOCKING` environment variable to 1.
This environment variable is used only by the Mali fbdev blob.
