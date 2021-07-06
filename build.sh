#!/bin/bash

RELEASE=r6p0
JOBS=$(nproc)
BUILD_OPTS="USING_UMP=0
	    BUILD=release
	    USING_PROFILING=0
	    MALI_PLATFORM=sunxi
	    USING_DVFS=1
	    USING_DEVFREQ=1"

apply_patches() {
    pushd $2

    quilt push -a
    if [ $? -ne 0 ]; then
        echo "Error applying patch $patch"
        exit 1
    fi

    popd
}

unapply_patches() {
    pushd $2

    quilt pop -a
    if [ $? -ne 0 ]; then
        echo "Error unapplying patch $patch"
        exit 1
    fi

    popd
}


build_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make JOBS=$JOBS $BUILD_OPTS -C $driver_dir
    if [ $? -ne 0 ]; then
	    echo "Error building the driver"
	    exit 1
    fi

    cp $driver_dir/mali.ko .
}

embed_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/
    local kernel_driver_dir=$KDIR/drivers/gpu/drm/mali/
    local Kconfig_append='source "drivers/gpu/drm/mali/Kconfig"'
    local Makefile_append="obj-y += mali/"

    rm -rf $kernel_driver_dir/*
    mkdir -p $kernel_driver_dir

    cp -r $driver_dir/* $kernel_driver_dir

    fgrep -q "$Kconfig_append" $kernel_driver_dir../Kconfig || echo -e "\n$Kconfig_append" >> $kernel_driver_dir../Kconfig
    fgrep -q "$Makefile_append" $kernel_driver_dir../Makefile || echo $Makefile_append >> $kernel_driver_dir../Makefile
}

install_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make JOBS=$JOBS $BUILD_OPTS -C $driver_dir install
}

clean_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make JOBS=$JOBS $BUILD_OPTS -C $driver_dir clean
}

while getopts "j:r:aubcite" opt
do
    case $opt in
	a)
	    echo "applying patches"
	    apply_patches $(pwd)/patches $RELEASE
	    ;;
	b)
	    echo "building..."
	    apply_patches $(pwd)/patches $RELEASE
	    build_driver $RELEASE
	    ;;
	c)
	    echo "cleaning..."
	    unapply_patches $(pwd)/patches $RELEASE
	    clean_driver $RELEASE
	    ;;
	e)
	    echo "embedding into the kernel..."
	    apply_patches $(pwd)/patches $RELEASE
	    embed_driver $RELEASE
	    ;;
	i)
	    echo "installing..."
	    install_driver $RELEASE
	    ;;
	j)
	    JOBS=$OPTARG
	    ;;
	r)
	    case $OPTARG in
		r6p0 | r6p2 | r8p1 | r9p0)
		    RELEASE=$OPTARG
		    ;;
		*)
		    echo "Unsupported release"
		    exit 1
	    esac
	    ;;
	u)
	    echo "unapplying patches"
	    unapply_patches $(pwd)/patches $RELEASE
	    ;;
	t)
	    echo "Generating travis-ci YAML"
	    cat travis-base.yml > .travis.yml
	    ./travis.py >> .travis.yml
	    ;;
	\?)
	    echo "invalid option -$OPTARG"
	    exit 1
	    ;;
    esac
done

exit 0
