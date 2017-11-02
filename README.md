# Mali support for Allwinner / Sunxi platform for mainline Linux

In order to get GPU support to work on your Allwinner platform, you will need:

1. The kernel-side driver, which is in this repository
2. The [Device Tree description of the GPU](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/devicetree/bindings/gpu/arm,mali-utgard.txt)
3. The userspace blob, available on Free Electrons [mali-blobs GitHub](https://github.com/free-electrons/mali-blobs)  repository

## Setting it up

1. Add device tree definition to device's devicetree
2. Compile the kernel module (from this repository):
```
git clone https://github.com/mripard/sunxi-mali.git
cd sunxi-mali
export CROSS_COMPILE=$TOOLCHAIN_PREFIX
export KDIR=$KERNEL_BUILD_DIR
export INSTALL_MOD_PATH=$TARGET_DIR
./build.sh -r r6p2 -b
./build.sh -r r6p2 -i
```
It should install the mali.ko Linux kernel module into the target filesystem.

3. Fetch the OpenGL userspace blobs that match your setup (either fbdev or X11-dma-buf variant)
```
git clone https://github.com/free-electrons/mali-blobs.git
cd mali-blobs
cp -a r6p2/fbdev/lib/lib_fb_dev/lib* $TARGET_DIR/usr/lib
```
