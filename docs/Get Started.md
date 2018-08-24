---
# Installation
---

First of all, you have to download LIKO-12, it's available at:

- [GitHub Releases](https://github.com/RamiLego4Game/LIKO-12/releases)
- [Itch.io](https://ramilego4game.itch.io/liko12)
- [Google Play](https://play.google.com/store/apps/details?id=me.ramilego4game.liko12) (Recommended for android users)

---
## Windows
---

1. Download the windows build `..._Windows.zip`
2. Right click the `.zip` file and press `Extract All...`
3. Double click `LIKO-12.exe` in the extracted folder and enjoy !

---
## Linux
---

### Method A (Recommended):

!> Not installing LuaSec would disable HTTP**S** connection support in LIKO-12.

1. Install LÖVE 11.1 from [http://love2d.org](http://love2d.org)
  - If using debian doing the following would install it:
    1. Add LÖVE PPA to your system `sudo add-apt-repository ppa:bartbes/love-stable`.
    2. APT Update `sudo apt update`.
    3. Install LÖVE `sudo apt install love`.
2. Download the universal `.love` file `..._Universal.love`
3. Install LuaSec (For https support, _optional_):
  - If using debian:
    - `sudo apt install luasec`
  - Otherwise use [luarocks](https://luarocks.org/):
    - `sudo luarocks install luasec`
4. Open a terminal in the folder containing the `.love` file.
5. Execute `love LIKO-12_..._Universal.love` and enjoy !

> If you failed to install LuaSec in any way, you can try to install libcurl as a replacement.

### Method B (Works only for x86_64 systems):

!> The .AppImage can't open it's data folder, and the data folder location is also unknown.

1. Download the Linux .AppImage `..._Linux_x86_64.AppImage`.
2. Make it executable `chmod u+x LIKO-12_..._Linux_x86_64.AppImage`.
3. Install LuaSec (For https support, _optional_):
  - If using debian:
    - `sudo apt install luasec`
  - Otherwise use [luarocks](https://luarocks.org/):
    - `sudo luarocks install luasec`
4. Execute the .AppImage `./LIKO-12_..._Linux_x86_64.AppImage`.

> If you failed to install LuaSec in any way, you can try to install libcurl as a replacement.

---
## OS X
---

?> HTTP**S** support in LIKO-12 should work out of the box in OS X (using libcurl, which is pre-installed in OS X).

### Method A (Recommended):

1. Install LÖVE 11.1 from [http://love2d.org](http://love2d.org)
2. Download the universal `.love` file `..._Universal.love`
3. Run the universal `.love` using LÖVE 11.1.

### Method B (Unsupported):

!> I have no idea if those builds work or not, if you have time to spare for fixing them, then create a [GitHub issue](https://github.com/RamiLego4Game/LIKO-12/issues).

1. Download the `..._Mac.zip` build.
2. Extract the `.zip` (I've been told you have to use a third-party tool for LIKO-12 to work).
3. Run LIKO-12 app and enjoy !

---
## Android
---

It's highly suggested to install LIKO-12 from [Google Play](https://play.google.com/store/apps/details?id=me.ramilego4game.liko12).

But if you choose not to do that, then `..._Android.apk` is provided in GitHub releases and itch.io.

The idea is that you can't switch between LIKO-12 from Google play, and LIKO-12 from other sources, without wiping it's data (so backup it first).

That's because Google signs LIKO-12 with a different key when downloaded from Google Play.

---
# What's next
---

You can start reading [LIKO-12's documentation](/Documentation/)