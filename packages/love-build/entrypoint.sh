#!/bin/sh -l

mkdir $GITHUB_WORKSPACES/love-builds

cd $GITHUB_WORKSPACES/$INPUT_PATH

echo Removing unnecessary files
rm -v -f $INPUT_EXCLUDED_FILES
rm -v -f -r $INPUT_EXCLUDED_DIRS

wget -O "../BuildUtils/LIKO-12_Android.apk" "github.com/LIKO-12/Build-Templates/releases/latest/download/LIKO-12_Android.apk"
wget -O "../BuildUtils/LIKO-12_x86_64_Linux.AppImage" "github.com/LIKO-12/Build-Templates/releases/latest/download/LIKO-12_x86_64_Linux.AppImage"
wget -O "../BuildUtils/LIKO-12_macOS.zip" "github.com/LIKO-12/Build-Templates/releases/latest/download/LIKO-12_macOS.zip"
wget -O "../BuildUtils/LIKO-12_x86_64_Windows.zip" "github.com/LIKO-12/Build-Templates/releases/latest/download/LIKO-12_x86_64_Windows.zip"
wget -O "../BuildUtils/LIKO-12_i686_Windows.zip" "github.com/LIKO-12/Build-Templates/releases/latest/download/LIKO-12_i686_Windows.zip"

echo Packing .love file
7z A -r -y -tzip -bd "../love-builds/$INPUT_NAME.love" .

mkdir ./temp
cd ../temp

echo Building Windows
7z E -r -y -tzip ../BuildUtils/LIKO-12_x86_64_Windows.zip
cat love_win64/love.exe $GITHUB_WORKSPACES/$INPUT_PATH/"$INPUT_NAME".love > Windows_x86_64/"$INPUT_NAME".exe
cat love_win64/lovec.exe $GITHUB_WORKSPACES/$INPUT_PATH/"$INPUT_NAME".love > Windows_x86_64/"$INPUT_NAME"_Console.exe
7z A -r -y -tzip -bd ../BuildUtils/LIKO-12_x86_64_Windows.zip Windows_x86_64/*

7z E -r -y -tzip ../BuildUtils/LIKO-12_i686_Windows.zip
cat love_win64/love.exe $GITHUB_WORKSPACES/$INPUT_PATH/"$INPUT_NAME".love > Windows_i686/"$INPUT_NAME".exe
cat love_win64/lovec.exe $GITHUB_WORKSPACES/$INPUT_PATH/"$INPUT_NAME".love > Windows_i686/"$INPUT_NAME"_Console.exe
7z A -r -y -tzip -bd ../BuildUtils/LIKO-12_i686_Windows.zip Windows_x86_64/*

echo Building Linux x86_64
../BuildUtils/LOVE-x86_64.AppImage --appimage-extract
cat squashfs-root/usr/bin/love "$INPUT_NAME".love > squashfs-root/usr/bin/love-fused
rm -v -f squashfs-root/usr/bin/love
mv -v -f squashfs-root/usr/bin/love-fused squashfs-root/usr/bin/love
chmod a+x squashfs-root/usr/bin/love

../BuildUtils/appimagetool.AppImage squashfs-root
mv -v -f ../BuildUtils/LOVE-x86_64.AppImage ../BuildUtils/LOVE-x86_64.AppImage
rm -v -f -r squashfs-root

echo Building OS_X
7z E -r -y -tzip ../BuildUtils/LIKO-12_macos.zip
cp -v -f "$INPUT_NAME".love ../BuildUtils/home/runner/work/Build-Templates/Build-Templates/love_macos/"$INPUT_NAME".app/Contents/Resources/"$INPUT_NAME".love
7z A -r -y -tzip -bd LIKO-12_macOS.zip ../BuildUtils/home/runner/work/Build-Templates/Build-Templates/love_macos/*

echo Building Android
apktool d -s -o love_decoded ../BuildUtils/LIKO-12_Android.apk
mkdir love_decoded/assets
cp ../love-builds/$INPUT_NAME.love love_decoded/assets/game.love
apktool b -o ../BuildUtils/LOVE.apk love_decoded

echo Building Universal
cp -v -f ../love-builds/$INPUT_NAME.love "$INPUT_NAME"_Nightly_Universal.love

mkdir ../Builds
cd ../Builds

cp -v -f ../BuildUtils/"$INPUT_NAME"_Nightly_Universal.love "$INPUT_NAME"_Universal.love
cp -v -f ../BuildUtils/"$INPUT_NAME"_i686_Windows.zip "$INPUT_NAME"_i686_Windows.zip
cp -v -f ../BuildUtils/"$INPUT_NAME"_x86_64_Windows.zip "$INPUT_NAME"_x86_64_Windows.zip
cp -v -f ../BuildUtils/LOVE-x86_64.appimage "$INPUT_NAME"_x86_64.appimage
cp -v -f ../BuildUtils/"$INPUT_NAME"_macos.zip "$INPUT_NAME"_macos.zip
cp -v -f ../BuildUtils/"LOVE.apk "$INPUT_NAME"_Android.apk
