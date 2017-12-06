#!/bin/bash

RELEASE=r6p0

BUILD_OPTS="USING_UMP=0
	    BUILD=release
	    USING_PROFILING=0
	    MALI_PLATFORM=sunxi
	    USING_DVFS=1
	    USING_DEVFREQ=1"

apply_patches() {
    pushd $2

    for patch in $1/*.patch;
    do
	patch -sf -p1 < $patch
	if [ $? -ne 0 ]; then
		echo "Error applying patch $patch"
		exit 1
	fi
    done

    popd
}

unapply_patches() {
    pushd $2

    patches=($1/*.patch)
    for ((i=${#patches[@]}-1; i>=0; i--));
    do
	patch -R -p1 < "${patches[$i]}"
    done

    popd
}


build_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make $BUILD_OPTS -C $driver_dir
    if [ $? -ne 0 ]; then
	    echo "Error building the driver"
	    exit 1
    fi

    cp $driver_dir/mali.ko .
}

install_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make $BUILD_OPTS -C $driver_dir install
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
	    case $OPTARG in
		r6p0 | r6p2)
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
	\?)
	    echo "invalid option -$OPTARG"
	    exit 1
	    ;;
    esac
done

exit 0
