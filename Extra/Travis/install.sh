#!/bin/bash

echo ----==== Installing 7zip ====----

sudo apt-get -qq update
sudo apt-get install -qq p7zip-full

echo ----==== Install luacheck ====----

sudo apt-get install -qq luarocks
sudo luarocks install luacheck

echo ----==== Downloading build templates ====----

git clone https://github.com/LIKO-12/Nightly.git ../BuildUtils

echo ----==== Downloading AppImage toolkit ====----

wget -O "../BuildUtils/appimagetool.AppImage" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-"$(uname -m)".AppImage"
chmod a+x ../BuildUtils/appimagetool.AppImage
