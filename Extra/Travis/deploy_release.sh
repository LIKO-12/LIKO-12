#!/bin/bash

echo ----------------------------------------------
echo ----==== Deploying To Github Releases ====----
echo ----------------------------------------------
echo - Creating the new release

gothub release \
  --user RamiLego4Game \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "Draft Release" \
  --description "Please wait for @RamiLego4Game to setup this release." \
  --draft

echo ----==== Uploading the builds ====----

echo - Uploading windows build

gothub upload \
  --user RamiLego4Game \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_PRE_Windows.zip" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Windows.zip \
  --replace

echo - Uploading linux build

gothub upload \
  --user RamiLego4Game \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_PRE_Linux_x86_64.AppImage" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Linux_x86_64.AppImage \
  --replace

echo - Uploading mac build

gothub upload \
  --user RamiLego4Game \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_PRE_Mac.zip" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Mac.zip \
  --replace

echo - Uploading universal build

gothub upload \
  --user RamiLego4Game \
  --repo LIKO-12 \
  --tag $TRAVIS_TAG \
  --name "LIKO-12_V"$TRAVIS_TAG"_PRE_Universal.love" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Universal.love \
  --replace

echo ----==== Done ====----

echo -----------------------------------------
echo ----==== Deploying To itch.io ====----
echo -----------------------------------------
echo - Renaming the builds
cp -v -f "../BuildUtils/Builds/LIKO-12_Nightly_*" "../BuildUtils/Builds/LIKO-12_V"$TRAVIS_TAG"_PRE_*"