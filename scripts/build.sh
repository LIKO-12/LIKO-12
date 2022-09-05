#!/usr/bin/env bash
set -e;

if [ ! -d 'src' ]; then
    echo "Error: The script should be run with the root of the repository as the working directory." >&2;
    exit 1;
fi

[ -d 'dist' ] || mkdir 'dist';

(cd src; zip -r ../dist/release.love *);