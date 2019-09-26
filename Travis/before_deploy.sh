#!/bin/bash

echo ----==== Copying files into other directory ====----

mkdir ../BuildUtils/Builds
mkdir ../BuildUtils/LIKO-12
cp -v -f -r ./* ../BuildUtils/LIKO-12/
cd ../BuildUtils/LIKO-12/

echo ----==== Removing unnecessary files... ====----

rm -v -f README.md CODE_OF_CONDUCT.md CONTRIBUTING.md PULL_REQUEST_TEMPLATE.md .travis.yml .gitattributes .gitignore .nomedia
rm -v -f -r .git .github .vscode Travis snap

echo ----==== Packing .love file ====----

7z A -r -y -tzip -bd "../LIKO-12.love" .
cd ..

echo ----==== Building Windows 32bit ====----

cat Windows_x86/love.exe LIKO-12.love > Windows_x86/LIKO-12.exe
cat Windows_x86/lovec.exe LIKO-12.love > Windows_x86/LIKO-12_Console.exe
rm -v -f Windows_x86/love.exe
rm -v -f Windows_x86/lovec.exe
7z A -r -y -tzip -bd Builds/LIKO-12_Nightly_Windows.zip Windows_x86/*

echo ----==== Building Linux x86_64 ====----

Linux_x86_64/Love/LIKO-12-x86_64.AppImage --appimage-extract
cat squashfs-root/usr/bin/love LIKO-12.love > squashfs-root/usr/bin/love-fused
rm -v -f squashfs-root/usr/bin/love
mv -v -f squashfs-root/usr/bin/love-fused squashfs-root/usr/bin/love
chmod a+x squashfs-root/usr/bin/love
./appimagetool.AppImage squashfs-root
mv -v -f LIKO-12-x86_64.AppImage Builds/LIKO-12_Nightly_Linux_x86_64.AppImage
rm -v -f -r squashfs-root

echo ----==== Building OS_X ====----

cp -v -f LIKO-12.love OS_X/LIKO-12.app/Contents/Resources/LIKO-12.love
7z A -r -y -tzip -bd Builds/LIKO-12_Nightly_Mac.zip OS_X/*

echo ----==== Copying Universal... ====----
  
cp -v -f LIKO-12.love Builds/LIKO-12_Nightly_Universal.love

echo ----==== Downloading Deployment Tools ====----

echo Downloading gothub
go get github.com/itchio/gothub

echo Downloading butler

curl https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default --output ~/temp/butler.zip
unzip ~/temp/butler.zip
mv -v -f ~/temp/butler ~/bin/butler
chmod 755 ~/bin/butler

echo ----==== Done ====----

cd ../LIKO-12/
