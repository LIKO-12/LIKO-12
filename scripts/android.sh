#!/usr/bin/env bash
set -e;

# TODO: Don't override them when already set.
LOVE_VERSION='11.4';
LIKO_VERSION='2.0.0';

if [ ! -d 'src' ]; then
    echo "Error: The script should be run with the root of the repository as the working directory." >&2;
    exit 1;
fi

if [ ! -d '../android' ]; then
    echo "Error: Please clone the LIKO-12/android repository into ../android." >&2;
    exit 1;
fi

#--------------------------------------------------------------------------------#

function section {
    echo '';
    echo "--[[ $* ]]--";
    echo '';
}

#--------------------------------------------------------------------------------#

if [ -d '../android/app/src/embed/assets' ]; then
    section 'Cleaning Up Previous Build Junk';
    rm -rv '../android/app/src/embed/assets';
fi

[ -d 'dist' ] || mkdir 'dist'; # for doing the scripts operations in.
[ -d 'dist/tools' ] || mkdir 'dist/tools'; # for storing build tools.
[ -d 'dist/love' ] || mkdir 'dist/love'; # for storing original love binaries.
[ -d 'dist/temp' ] || mkdir 'dist/temp'; # for storing temporary working directory.
[ -d 'dist/out' ] || mkdir 'dist/out'; # for storing the result packages.

#--------------------------------------------------------------------------------#

section 'Copy Application Code';

cp -rv src ../android/app/src/embed/assets;

#--------------------------------------------------------------------------------#

section 'Build Android Application';

(cd ../android; ./gradlew --console=plain --build-cache assembleEmbedRelease bundleEmbedNoRecordRelease);

#--------------------------------------------------------------------------------#

section 'Cleanup';

rm -rv ../android/app/src/embed/assets/*;
touch ../android/app/src/embed/assets/.gitkeep;

# #--------------------------------------------------------------------------------#

# section 'Completed The Build Successfully';

# echo 'Check for the result files in the "dist/out" directory:';
# echo '';
# echo '- dist/out/liko_linux.AppImage';
