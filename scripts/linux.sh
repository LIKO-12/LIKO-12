#!/usr/bin/env bash
set -e;

# TODO: Don't override them when already set.
LOVE_VERSION='11.4';
LIKO_VERSION='2.0.0';

appimagetool='dist/tools/appimagetool.AppImage';

if [ ! -d 'src' ]; then
    echo "Error: The script should be run with the root of the repository as the working directory." >&2;
    exit 1;
fi

#--------------------------------------------------------------------------------#

function section {
    echo '';
    echo "--[[ $* ]]--";
    echo '';
}

#--------------------------------------------------------------------------------#

if [ -d 'dist/temp' ]; then
    section "Cleaning Up Previous Build Junk";
    rm -rv 'dist/temp';
fi

[ -d 'dist' ] || mkdir 'dist'; # for doing the scripts operations in.
[ -d 'dist/tools' ] || mkdir 'dist/tools'; # for storing build tools.
[ -d 'dist/love' ] || mkdir 'dist/love'; # for storing original love binaries.
[ -d 'dist/temp' ] || mkdir 'dist/temp'; # for storing temporary working directory.
[ -d 'dist/out' ] || mkdir 'dist/out'; # for storing the result packages.

#--------------------------------------------------------------------------------#

section 'Download Building Materials';

declare -A materials=(
    [$appimagetool]='https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage'
    ["dist/love/love-${LOVE_VERSION}-x86_64.AppImage"]="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage"
);

for filename in ${!materials[@]}; do
    if [ -a $filename ]; then
        echo "- Skipping $filename: already exists.";
        continue;
    fi

    echo "- $filename: ${materials[$filename]}";
    curl -o $filename -L ${materials[$filename]} --fail-with-body;

    if [[ $filename =~ .AppImage$ ]]; then
        echo 'Made the file executable.';
        chmod u+x $filename;
    fi
done

#--------------------------------------------------------------------------------#

section 'Pack Universal .love File';

(cd src; zip -r ../dist/temp/release.love *);

#--------------------------------------------------------------------------------#

section 'Extract LOVE';

(cd 'dist/temp'; "../love/love-${LOVE_VERSION}-x86_64.AppImage" --appimage-extract);

#--------------------------------------------------------------------------------#

section 'Cleanup Unneeded Files';

cleanup=(
    'share/mime'
    'share/icons'
    'share/applications/love.desktop'
    'share/pixmaps/love.svg'
    'love.desktop'
    'love.svg'
);

for target in ${cleanup[@]}; do
    rm -rv "dist/temp/squashfs-root/${target}";
done

#--------------------------------------------------------------------------------#

section 'Add Necessary Files';

cp -v 'scripts/assets/icon.svg' 'dist/temp/squashfs-root/LIKO-12.svg';
cp -v 'scripts/assets/icon.svg' 'dist/temp/squashfs-root/share/pixmaps/LIKO-12.svg';

cp -v 'scripts/assets/LIKO-12.desktop' 'dist/temp/squashfs-root/LIKO-12.desktop';
cp -v 'scripts/assets/LIKO-12.desktop' 'dist/temp/squashfs-root/share/applications/LIKO-12.desktop';

#--------------------------------------------------------------------------------#

section 'Fuse The Application';

cat 'dist/temp/squashfs-root/bin/love' 'dist/temp/release.love' > 'dist/temp/squashfs-root/bin/LIKO-12';
chmod +x 'dist/temp/squashfs-root/bin/LIKO-12';
echo '- Fused dist/temp/squashfs-root/bin/LIKO-12';

#--------------------------------------------------------------------------------#

section 'Pack The Image';

if [[ -a 'dist/out/liko_linux.AppImage' ]]; then rm -v 'dist/out/liko_linux.AppImage'; fi
$appimagetool 'dist/temp/squashfs-root' 'dist/out/liko_linux.AppImage';

#--------------------------------------------------------------------------------#

section 'Cleanup';

rm -rv 'dist/temp';

#--------------------------------------------------------------------------------#

section 'Completed The Build Successfully';

echo 'Check for the result files in the "dist/out" directory:';
echo '';
echo '- dist/out/liko_linux.AppImage';
