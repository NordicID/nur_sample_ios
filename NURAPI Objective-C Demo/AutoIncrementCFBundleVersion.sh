#!/bin/bash

PROJECTMAIN=$(pwd)
PROJECT_NAME="${TARGET_NAME}" 

#
if [[ -f "${PROJECTMAIN}/Info.plist" ]]
then
        INFOPLIST_FILE="${PROJECTMAIN}/Info.plist"
else
        echo -e "Can't find the plist: Info.plist"
        exit 1
fi

echo "Using file: ${INFOPLIST_FILE}"

#
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}" 2>/dev/null)

if [[ "${BUNDLE_VERSION}" = "" ]]
then
        echo -e "\"${INFOPLIST_FILE}\" does not contain key: \"CFBundleVersion\""
        exit 1
fi


# always incremented bundle version
NEW_BUILD_NUMBER=$(($BUNDLE_VERSION + 1))

echo "Build number: ${NEW_BUILD_NUMBER}"

# write back
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD_NUMBER}" "$INFOPLIST_FILE"
