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

## Installing the user-space components

Once the driver is compiled and loaded, you'll need to integrate the OpenGL ES
implementation.

In order to do that, you'll need to do the following commands (assuming you
want the fbdev version over the X11-dma-buf one).

```
git clone https://github.com/free-electrons/mali-blobs.git
cd mali-blobs
cp -a r6p2/fbdev/lib/lib_fb_dev/lib* $TARGET_DIR/usr/lib
```

## fbdev quirks

The fbdev variants are meant to deal with applications using the legacy fbdev
interface. The most widely used example would be [Qt](https://www.qt.io/). In
such a case, you'll need to do a few more things in order to have a working
setup.

The first thing needed would be to add a reserved memory region, shared by the
Display Engine and the Mali GPU nodes. The binding is defined
[here](https://www.kernel.org/doc/Documentation/devicetree/bindings/reserved-memory/reserved-memory.txt).
You'll obviously need to adjust the size depending on your needs.

```
/ {
	reserved-memory {
		#address-cells = <1>;
		#size-cells = <1>;
		ranges;

		cma: cma {
			compatible = "shared-dma-pool";
			size = <0x4000000>;
			reusable;
		};
	};
};
```

You'll then need to add the `memory-region` property pointing to that CMA
region in both the display engine and Mali nodes.

The Mali blob then uses framebuffer panning to implement multiple buffering.
Therefore, the kernel needs to allocate buffers at least twice the size (for
double buffering) of the actual resolution, which it doesn't by default. For
you to change that, you'll need to change either the
`CONFIG_DRM_FBDEV_OVERALLOC` option or the `drm_kms_helper.drm_fbdev_overalloc`
parameter to 100 times the number of simultaneous buffers you want to use (so
200 for double buffering, 300 for triple buffering, etc.).

To avoid screen tearing, set the `FRONTBUFFER_LOCKING` environment variable to 1.
This environment variable is used only by the Mali fbdev blob.
