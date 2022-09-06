#!/usr/bin/env bash
set -e;

# TODO: Don't override them when already set.
LOVE_VERSION='11.4';
LIKO_VERSION='2.0.0';

# TODO: Tag the LIKO-12 build
# TODO: Cleanup before building
# TODO: Better folders structure

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
    ["dist/7zr.exe"]="https://www.7-zip.org/a/7zr.exe"
    ["dist/7z-extra.7z"]="https://www.7-zip.org/a/7z2201-extra.7z"
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
        continue;
        echo "Error: failed to extract because of artifacts from a previous build." >&2;
        echo "Run the cleaning script then retry." >&2;
        exit 1;
    fi

    echo "- Extracting ${extract[$destination]} -> $destination";
    echo "";
    unzip -j ${extract[$destination]} -d $destination;
    echo "";
done

echo "- Extracting dist/7z-extra.7z/x64 -> dist/7z";
dist/7zr.exe e dist/7z-extra.7z -odist/7z -y x64/*

#--------------------------------------------------------------------------------#

section "Patch Executables Metadata";

for arch in 'win32' 'win64'; do
    echo "- Patch love.exe ($arch)";
    dist/rcedit-x64.exe "dist/love_${arch}/love.exe" \
        --set-icon scripts/assets/icon.ico \
        --set-file-version $LIKO_VERSION \
        --set-product-version $LIKO_VERSION \
        --set-version-string FileDescription 'An open-source fantasy computer' \
        --set-version-string CompanyName 'Rami Sabbagh' \
        --set-version-string LegalCopyright 'Copyright ⓒ 2017-2022 Rami Sabbagh' \
        --set-version-string ProductName 'LIKO-12' \
        --set-version-string OriginalFilename 'LIKO-12.exe';
    
    echo "- Patch lovec.exe ($arch)";
    dist/rcedit-x64.exe "dist/love_${arch}/lovec.exe" \
        --set-icon scripts/assets/icon.ico \
        --set-file-version $LIKO_VERSION \
        --set-product-version $LIKO_VERSION \
        --set-version-string FileDescription 'An open-source fantasy computer (terminal/console version)' \
        --set-version-string CompanyName 'Rami Sabbagh' \
        --set-version-string LegalCopyright 'Copyright ⓒ 2017-2022 Rami Sabbagh' \
        --set-version-string ProductName 'LIKO-12' \
        --set-version-string OriginalFilename 'liko12c.exe';
done

#--------------------------------------------------------------------------------#

section "Cook The Pachages";

for arch in 'win32' 'win64'; do
    echo "- Fuse LIKO-12.exe ($arch)";
    cat "dist/love_${arch}/love.exe" dist/release.love > "dist/love_${arch}/LIKO-12.exe";
    echo "- Fuse liko12c.exe ($arch)";
    cat "dist/love_${arch}/lovec.exe" dist/release.love > "dist/love_${arch}/liko12c.exe";
    echo '- Cleanup old executables';
    rm -v "dist/love_${arch}/love.exe" "dist/love_${arch}/lovec.exe";

    echo '- Remove unnecessary files';
    rm -v "dist/love_${arch}/readme.txt" "dist/love_${arch}/changes.txt"\
        "dist/love_${arch}/love.ico" "dist/love_${arch}/game.ico";

    echo '- Add license files';
    mv -v "dist/love_${arch}/license.txt" "dist/love_${arch}/LOVE-LICENSE.txt";
    cp -v "LICENSE" "dist/love_${arch}/LIKO-12-LICENSE.txt";
done

#--------------------------------------------------------------------------------#

section "Archive The Packages";

for arch in 'win32' 'win64'; do
    (cd "dist/love_${arch}"; ../7z/7za.exe a "../liko_${arch}.zip" -tzip *);
done

#--------------------------------------------------------------------------------#

section "Cleanup";

rm -rv "dist/love_win32" "dist/love_win64" "dist/7z";