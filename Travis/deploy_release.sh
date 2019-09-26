#!/bin/bash

echo ----------------------------------------------
echo ----==== Deploying To Github Releases ====----
echo ----------------------------------------------
echo - Creating the new release

gothub release \
  --user LIKO-12 \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "Draft Release" \
  --description "Please wait for @RamiLego4Game or @LIKO-12/collaborators to setup this release." \
  --draft

echo ----==== Uploading the builds ====----

echo - Uploading windows build

gothub upload \
  --user LIKO-12 \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_Windows.zip" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Windows.zip \
  --replace

echo - Uploading linux build

gothub upload \
  --user LIKO-12 \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_Linux_x86_64.AppImage" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Linux_x86_64.AppImage \
  --replace

echo - Uploading mac build

gothub upload \
  --user LIKO-12 \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_Mac.zip" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Mac.zip \
  --replace

echo - Uploading universal build

gothub upload \
  --user LIKO-12 \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_Universal.love" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Universal.love \
  --replace

echo -----------------------------------------
echo ----==== Deploying To itch.io ====----
echo -----------------------------------------
echo 
echo ----==== Renaming the builds ====----

mv -v -f "../BuildUtils/Builds/LIKO-12_Nightly_Windows.zip" "../BuildUtils/Builds/LIKO-12_V"$TRAVIS_TAG"_Windows.zip"
mv -v -f "../BuildUtils/Builds/LIKO-12_Nightly_Linux_x86_64.AppImage" "../BuildUtils/Builds/LIKO-12_V"$TRAVIS_TAG"_Linux_x86_64.AppImage"
mv -v -f "../BuildUtils/Builds/LIKO-12_Nightly_Mac.zip" "../BuildUtils/Builds/LIKO-12_V"$TRAVIS_TAG"_Mac.zip"
mv -v -f "../BuildUtils/Builds/LIKO-12_Nightly_Universal.love" "../BuildUtils/Builds/LIKO-12_V"$TRAVIS_TAG"_Universal.love"

echo ----=== Uploading the builds ====----

cd ../BuildUtils/
butler push "./Builds/LIKO-12_V"$TRAVIS_TAG"_Windows.zip" ramilego4game/liko12:windows
butler push "./Builds/LIKO-12_V"$TRAVIS_TAG"_Linux_x86_64.AppImage" ramilego4game/liko12:linux
butler push "./Builds/LIKO-12_V"$TRAVIS_TAG"_Mac.zip" ramilego4game/liko12:osx
butler push "./Builds/LIKO-12_V"$TRAVIS_TAG"_Universal.love" ramilego4game/liko12:src

echo ----==== Done ====----
