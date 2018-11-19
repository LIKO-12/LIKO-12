#!/bin/bash

echo ----==== Installing 7zip ====----

sudo apt-get -qq update
sudo apt-get install -qq p7zip-full

echo ----==== Installing luacheck ====----

sudo apt-get install -qq luarocks
sudo luarocks install luacheck

echo ----==== Downloading build templates ====----

git clone https://github.com/LIKO-12/Nightly.git ../BuildUtils

echo ----==== Downloading AppImage toolkit ====----

wget -O "../BuildUtils/appimagetool.AppImage" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-"$(uname -m)".AppImage"
chmod a+x ../BuildUtils/appimagetool.AppImage

echo ----==== Downloading ApkTool ====---

wget -O "../BuildUtils/apktool.jar" "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.3.4.jar"
chmod a+x ../BuildUtils/apktool.jar

echo ----==== Installing supply ====----

rvm install 2.5.3
gem install fastlane supply
