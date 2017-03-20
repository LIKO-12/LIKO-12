# LIKO-12
LIKO-12 is a PICO-8 clone but with extra abilities, different API and bigger screen width.

We are working on this because PICO-8 is not available under a free license that allows
improvements and sharing, and also to lift some of the more restrictive limitations on games
like the token limit.

What's PICO-8 ??

* PICO-8 is a fantasy console for making, sharing and playing tiny games and other computer programs. When you turn it on, the machine greets you with a shell for typing in Lua programs straight away and provides simple built-in tools for creating sprites, maps and sound.

* LIKO-12 comes with a terminal, lua console, sprites editor and a code editor. It also comes with a modified pixel font which includes lower-case letters. We plan on adding a map editor and audio/music editor in the future.

* So you can basically create spritesheets, and games using this console.

## About LIKO-12 V0.6 W.I.P
A lot of you may saw some gifs of the new work in progress LIKO-12 V0.6, so here's some info about it:

After releasing LIKO-12 V0.0.5C I decided to recode LIKO-12 giving it a modular engine, With this engine I can add new features to LIKO-12 more easier.

And the new engine aims to give LIKO-12 more feelings of an old computer, by implementing a BIOS, Virtual HardDrives, etc.. (I wrote a complete post about them [here](https://love2d.org/forums/viewtopic.php?f=5&t=82913&sid=833fce88787f90bea3e42ec36b7405e4&start=30#p205731) )

After 6 months of silent updates, I managed to get LIKO-12 back to life, and started to post GIFs of it on [my twitter](https://twitter.com/ramilego4game).

So now the LIKO-12 has an OS called "DiskOS", that you can edit and hack yourself inside LIKO-12 itself.

## How can I run the W.I.P V0.6 with all the new features ?
In other words, you can say: "How can I run the DEV version that you tweet about ?"

#### The DEV version as it's called is a __*development*__ version, so you have to keep in mind:
* Things are not stable, so crashes can happen at __ANY__ time, so always save your data.
* Some API changes can happen at any time breaking any written games.
* Things are not polished nor finished, so expect some non-userfriendly content.

#### About the current BIOS:
* It automatically __REFLASHES__ the DISKOS at boot, so any modification to it will revert at reboot, instead edit /OS/DISKOS/ in the SRC.
* The boot animation will be changed soon.
* The bios configuration screen still doesn't exists.

#### About the current BIOS Configuration:
* Loads the GPU with pico-8 16 color palette at 192x168 resolution.
* Creates 2 virtual harddrives, C & D, each with 50 megabyte space.
* Creates a Keyboard and a mouse.

#### Running LIKO12 V0.6 DEV version:
You will have to clone the LIKO-12 repo, __Be sure to clone the WIP branch__.

##### Then you will have to install love2d:
###### Windows:
1. Go to http://love2d.org/ and download the love2d installer for your platform (32bit/64bit).
2. Install love2d.
3. Create a text file at your desktop, call it "run liko12"
4. Type in (Replace them with your pathes): 
```batch
"path to love" "path to clone directory"
```
For default 32bit installation, replace _likopath_ with the path to the cloned folder, it should contain main.lua.
```batch
"C://Program Files/LOVE/love" "likopath"
```
5. Save the text file as "run liko12 __.bat__ "
6. Run the batch file.
7. Be sure to always pull updates from the repo.
8. Enjoy :)

###### Linux (Ubuntu or Mint):
1. First open the terminal.
2. Add love2d repo by running those commands:
```sh
sudo add-apt-repository ppa:bartbes/love-stable
sudo apt-get update
```
3. Install love2d by running this command:
```sh
sudo apt-get install love
```
4. Enter the cloned LIKO-12 repo directory (that contains main.lua) and type this command to run:
```sh
love .
```
5. Be sure to always pull updates from the repo.
6. Enjoy :)

## Questions ?
Direct Message me at twitter (see link bellow), I will response as soon as possible.

## Links
- Twitter [@RamiLego4Game](https://twitter.com/ramilego4game) (I post daily/weekly gifs of the upcomming features of LIKO-12)
- Love2D Forums Topic: https://love2d.org/forums/viewtopic.php?f=5&t=82913

~~We have an irc channel #liko12 at irc.oftc.net , feel free to join us~~

---

# Old LIKO12 (V0.0.5C) Readme

## Launching LIKO-12

### Windows 32bit:
Extract the windows 32 build and run LIKO-12.exe

### All other opereating systems:
Download LÖVE framwork installer from https://love2d.org/ and double click the .love file to run.

## Old Screenshots
![gifrecording](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/gif_1.gif "Snake Demo Cart")
![gifrecording](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/gif_2.gif "Fire Demo Cart")
![gifrecording](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/gif_3.gif "TicTacToe Demo Cart")
![screenshot](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/screenshot_1.png "LIKO-12 Screenshot 1")
![screenshot](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/screenshot_2.png "LIKO-12 Screenshot 2")
![screenshot](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/screenshot_3.png "LIKO-12 Screenshot 3")
![screenshot](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/screenshot_4.png "LIKO-12 Screenshot 4")
![screenshot](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/screenshot_5.png "LIKO-12 Screenshot 5")
![screenshot](https://raw.githubusercontent.com/RamiLego4Game/LIKO-12/master/screenshot_6.png "LIKO-12 Screenshot 6")

## Old LIKO-12.txt
```
==========================================================================================
	LIKO-12 V0.0.5 PRE
	https://github.com/RamiLego4Game/LIKO-12
	Licensed under GPL-3, see LICENSE file for more info
	Author: RamiLego4Game // ramilego4game@gmail.com
	Contributors:
		technomancy: Co-Developer.
		gamax92: Gif recording.
		cosme12: Fire & Snake demo carts.
		OmgCopito95, s0r00t: For being awesome and contributing on github.
	
	LIKO-12 is built with:
		LÖVE Framework: http://love2d.org/
==========================================================================================
```
Continue Reading: https://github.com/RamiLego4Game/LIKO-12/blob/master/liko-12.txt
