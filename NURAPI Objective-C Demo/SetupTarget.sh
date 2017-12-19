#! /bin/sh

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 Targets/<target-files>.zip"
    exit 1
fi

ARCHIVE="$1"

if [[ ! -e $ARCHIVE ]]; then 
    echo $"No such file: ${ARCHIVE}"
    exit 1
fi

echo "Using target zip file: ${ARCHIVE}"

# get rid of the old assets so that there are no remains of the last target
rm -rf Source/TargetAssets.xcassets

unzip -o $ARCHIVE

echo "Done, now clean and rebuild the project"

