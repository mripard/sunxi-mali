#! /usr/bin/env python3

import feedparser

def retrieve_versions():
    doc = feedparser.parse("https://www.kernel.org/feeds/kdist.xml")
    versions = list()

    for entry in doc.entries:
        version = entry.title.split(':')[0].strip()
        if "next-" in version:
            continue

        major = int(version.split('.')[0])

        if "-rc" in version:
            minor = int(version.split('-')[0].split('.')[1])
        else:
            minor = int(version.split('.')[1])

        if major < 4:
            continue

        if minor < 4:
            continue

        versions.append(version)

    return versions

versions = retrieve_versions()
versions.reverse()

print("matrix:")
print("  include:")
for release in ("r6p0", "r6p2", ):
    for defconfig in ("multi_v7_defconfig", "sunxi_defconfig", ):
        for version in versions:
            if version.startswith("4.4") and defconfig is "sunxi_defconfig":
                continue

            print("    - env:")
            print("      - KERNEL_VERSION: %s" % version)
            print("        KERNEL_DEFCONFIG: %s" % defconfig)
            print("        MALI_VERSION: %s" % release)
