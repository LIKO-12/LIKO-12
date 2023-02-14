#!/usr/bin/env bash
set -e;

if [ ! -d 'packages' ]; then
    echo "Error: The script should be run with the root of the repository as the working directory." >&2;
    exit 1;
fi

#--------------------------------------------------------------------------------#

[ -d 'dist' ] || mkdir 'dist'; # for doing the scripts operations in.
[ -d 'dist/out' ] || mkdir 'dist/out'; # for storing the result packages.

#--------------------------------------------------------------------------------#

(cd packages/app/out; zip -r ../../../dist/out/liko_universal.love *);