#!/bin/bash

RELEASE=r6p0

apply_patches() {
    pushd $2

    for patch in $1/*.patch;
    do
	patch $3 -p1 < $patch
    done

    popd
}

build_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    USING_UMP=0 BUILD=release USING_PROFILING=0 MALI_PLATFORM=sunxi \
	     USING_DVFS=0 make -C $driver_dir

    cp $driver_dir/mali.ko .
}

install_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    USING_UMP=0 BUILD=release USING_PROFILING=0 MALI_PLATFORM=sunxi \
	     USING_DVFS=0 make -C $driver_dir install
}

while getopts "r:aubi" opt
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
	i)
	    echo "installing..."
	    install_driver $RELEASE
	    ;;
	r)
	    RELEASE=$OPTARG
	    ;;
	u)
	    echo "unapplying patches"
	    apply_patches $(pwd)/patches $RELEASE -R
	    ;;
	\?)
	    echo "invalid option -$OPTARG"
	    exit 1
	    ;;
    esac
done

exit 0
