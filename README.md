# LIKO-12
LIKO-12 is a PICO-8 clone but with extra abilities, different API and bigger screen width.

We are working on this because PICO-8 is not available under a free license that allows
improvements and sharing, and also to lift some of the more restrictive limitations on games
like the token limit.

* PICO-8 is a fantasy console for making, sharing and playing tiny games and other computer programs. When you turn it on, the machine greets you with a shell for typing in Lua programs straight away and provides simple built-in tools for creating sprites, maps and sound.

* LIKO-12 comes with a terminal, lua console, sprites editor and a code editor. It also comes with a modified pixel font which includes lower-case letters. We plan on adding a map editor and audio/music editor in the future.

* So you can basically create spritesheets, and games using this console.


### Running LIKO12

+ Clone the LIKO-12 repo, __Be sure to clone the WIP branch__.
+ Install love2d.

###### Windows

+ Create a text file at your desktop, call it "run liko12"
+ Type in (Replace them with your pathes): 
```batch
"path to love" "path to clone directory"
```
For default 32bit installation, replace _likopath_ with the path to the cloned folder, it should contain main.lua.
```batch
"C://Program Files/LOVE/love" "likopath"
```
+ Save the text file as "run liko12 __.bat__ "
+ Run the batch file.

###### Linux

+ Enter the cloned LIKO-12 repo directory (that contains main.lua) and type this command to run:
```sh
love .
```

### LIKO-12 V0.6 W.I.P

A lot of you may saw some gifs of the new work in progress LIKO-12 V0.6, so here's some info about it:

After releasing LIKO-12 V0.0.5C I decided to recode LIKO-12 giving it a modular engine, With this engine I can add new features to LIKO-12 more easier. And the new engine aims to give LIKO-12 more feelings of an old computer, by implementing a BIOS, Virtual HardDrives, etc.. (I wrote a complete post about them [here](https://love2d.org/forums/viewtopic.php?f=5&t=82913&sid=833fce88787f90bea3e42ec36b7405e4&start=30#p205731) )

After 6 months of silent updates, I managed to get LIKO-12 back to life, and started to post GIFs of it on [my twitter](https://twitter.com/ramilego4game). So now the LIKO-12 has an OS called "DiskOS", that you can edit and hack yourself inside LIKO-12 itself.

#### About the current BIOS:

* It automatically __REFLASHES__ the DISKOS at boot, so any modification to it will revert at reboot, instead edit /OS/DISKOS/ in the SRC.
* The boot animation will be changed soon.
* The bios configuration screen still doesn't exists.

#### About the current BIOS Configuration:

* Loads the GPU with pico-8 16 color palette at 192x168 resolution.
* Creates 2 virtual harddrives, C & D, each with 50 megabyte space.
* Creates a Keyboard and a mouse.

### Questions?
Direct Message me at twitter (see link bellow), I will response as soon as possible.

### Links

- Twitter [@RamiLego4Game](https://twitter.com/ramilego4game) (I post daily/weekly gifs of the upcomming features of LIKO-12)
- Love2D Forums Topic: https://love2d.org/forums/viewtopic.php?f=5&t=82913
