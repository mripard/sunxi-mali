#!/bin/bash

RELEASE=r6p0
JOBS=$(nproc)
BUILD_OPTS="USING_UMP=0 USING_PROFILING=0 MALI_PLATFORM=sunxi USING_DVFS=1 USING_DEVFREQ=1"
BUILD="release"

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

    make -C $driver_dir JOBS=$JOBS $BUILD_OPTS BUILD=$BUILD
    if [ $? -ne 0 ]; then
	    echo "Error building the driver"
	    exit 1
    fi

    cp $driver_dir/mali.ko .
}

install_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make -C $driver_dir install JOBS=$JOBS $BUILD_OPTS BUILD=$BUILD
}

clean_driver() {
    local driver_dir=$(pwd)/$RELEASE/src/devicedrv/mali/

    make -C $driver_dir clean JOBS=$JOBS $BUILD_OPTS BUILD=$BUILD
}

while getopts "j:m:r:aubcit" opt
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
	i)
	    echo "installing..."
	    install_driver $RELEASE
	    ;;
	j)
	    JOBS=$OPTARG
	    ;;
	m)
	    case $OPTARG in
		debug | release)
		    BUILD=$OPTARG
		    ;;
		*)
		    echo "Unsupported build mode"
		    exit 1
	    esac
	    ;;
	r)
	    case $OPTARG in
		r6p0 | r6p2 | r8p1)
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
