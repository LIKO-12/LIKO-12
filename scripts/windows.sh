#!/usr/bin/env bash
set -e;

LOVE_VERSION='11.4';

if [ ! -d 'src' ]; then
    echo "Error: The script should be run with the root of the repository as the working directory." >&2;
    exit 1;
fi

function section {
    echo '';
    echo "--[[ $* ]]--";
    echo '';
}

#--------------------------------------------------------------------------------#

section "Download Building Materials";

declare -A materials=(
    ["dist/rcedit-x64.exe"]="https://github.com/electron/rcedit/releases/download/v1.1.1/rcedit-x64.exe"
    ["dist/love_${LOVE_VERSION}_win64.zip"]="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-win64.zip"
    ["dist/love_${LOVE_VERSION}_win32.zip"]="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-win32.zip"
);

for filename in "${!materials[@]}"; do
    if [ -a $filename ]; then
        echo "- Skipping $filename: already exists.";
        continue;
    fi

    echo "- $filename: ${materials[$filename]}";
    curl -o $filename -L ${materials[$filename]} --fail-with-body;
done

#--------------------------------------------------------------------------------#

section "Extract Archives";

declare -A extract=(
    ["dist/love_win64"]="dist/love_${LOVE_VERSION}_win64.zip"
    ["dist/love_win32"]="dist/love_${LOVE_VERSION}_win32.zip"
);

for destination in "${!extract[@]}"; do
    if [ -a $destination ]; then
        echo "Error: failed to extract because of artifacts from a previous build." >&2;
        echo "Run the cleaning script then retry." >&2;
        exit 1;
    fi

    echo "- Extracting ${extract[$destination]} -> $destination";
    echo "";
    unzip -j ${extract[$destination]} -d $destination;
    echo "";
done

#--------------------------------------------------------------------------------#

section "Patch Executables";
