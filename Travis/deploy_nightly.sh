#!/bin/bash

echo -----------------------------------------
echo ----==== Deploying Nightly Build ====----
echo -----------------------------------------
echo - Editing existing TRAVIS release

gothub edit \
  --user LIKO-12 \
  --repo Nightly \
  --tag TRAVIS \
  --name "Build #${TRAVIS_BUILD_NUMBER}" \
  --description "[\`${TRAVIS_COMMIT}\`]: \`${TRAVIS_COMMIT_MESSAGE}\`" \
  --pre-release

echo ----==== Uploading the builds ====----

echo - Uploading windows build

gothub upload \
  --user LIKO-12 \
  --repo Nightly \
  --tag TRAVIS \
  --name "LIKO-12_Nightly_Windows.zip" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Windows.zip \
  --replace

echo - Uploading linux build

gothub upload \
  --user LIKO-12 \
  --repo Nightly \
  --tag TRAVIS \
  --name "LIKO-12_Nightly_Linux_x86_64.AppImage" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Linux_x86_64.AppImage \
  --replace

echo - Uploading mac build

gothub upload \
  --user LIKO-12 \
  --repo Nightly \
  --tag TRAVIS \
  --name "LIKO-12_Nightly_Mac.zip" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Mac.zip \
  --replace

echo - Uploading universal build

gothub upload \
  --user LIKO-12 \
  --repo Nightly \
  --tag TRAVIS \
  --name "LIKO-12_Nightly_Universal.love" \
  --file ../BuildUtils/Builds/LIKO-12_Nightly_Universal.love \
  --replace

echo ----==== Done ====----