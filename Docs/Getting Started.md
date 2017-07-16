# Welcome to LIKO-12 V0.6.0_PRE

LIKO-12 is an _open source_ **fantasy computer** completely written in the Lua programming language where you can make, play and share tiny retro-looking games and programs.

The LIKO-12 fantasy computer comes with a default, fully customizable, DOS-like operating system installed, called DiskOS, which provides an environment with basic command line programs and visual game editors.

Games are stored as disk files that can be saved, shared and uploaded to pastebin via the built-in program.

---

So, here's a list of the commands that you'll mostly use:

* **help**: Prints basic help info.
* **dir**: Prints current directory items, folders in green and files in white.
* **ls**: The same of dir, but with unix name.
* **load <FileName\>**: Loads a game into memory.
* **save <FileName\>**: Saves the game from the memory into a file.
* **save <FileName\> -c**: The same of above, but compresses the game.
* **run**: Runs/Plays the current game in memory.
* **install_demos**: Installs the built-in demos.
* **cd <DirectoryName\>**: Enters a specific directory.
* **cd ..**: Goes up one directory.
* **cd <DriveLetter\>:** : Changes the current active hard drive.
* **folder**: Opens the current directory in the host file explorer.
* **appdata**: Opens the LIKO-12 appdata folder in the host file explorer.
* **rm <FileName\>**: Deletes a file.
* **export <FileName\>.png**: Exports the spritesheet from memory (the black color will be transparent).
* **export <FileName\>.png --opaque**: The same of above, but with black as opaque.
* **import <FileName\>.png**: Imports the spritesheet from an image, all the colors not from the palette will be replaced by back.
* **pastebin**: Prints the Usage, Allows you to upload and download games, **Use save -c with before uploading !**
* **keymap**: Allows you to change the controllers keymap.
* **programs**: Lists the installed Programs (Not all of them are mentioned here).

**Note:** For the programs usage, type in LIKO-12 `<program> -?`, example: `export -?`.

---

If you press the _escape_ key, LIKO-12 will switch to the editors mode, at the top right you can click the buttons to switch between them, or by pressing `alt+left` / `alt+right` to cycle between them.

---

Currently LIKO-12 comes with three editors (and the others are being worked on):

* **SpriteSheet Editor**: Allows you to edit and draw sprites.
* **Tilemap Editor**: If your game requires a map, then this editor allowes you to draw the map and view it.
* **Code Editor**: Here you'll type in your game code, to bring your ideas to life.

---

If you wish to start creating games you can start be reading the demo games code, and checking the API functions documentation in this webpage.

* Inorder to program games, you'll have to learn [Lua](http://lua.org), A good way to do that is by visiting the [LuaTutorial Page](http://lua-users.org/wiki/Tutorial) in the Lua wiki, note that LIKO-12 uses **Lua 5.1**.


**To load and play a demo game:**

1. Install the demos !, By typing `install_games` in the terminal.
2. Enter the demos directory: `cd Demos`.
3. To get a list of the available games do `dir`.
4. Load a demo game by typing `load <gameName>`, note that you don't have to enter the _.lk12_ extension.
5. You can press _escape_ to view the game source.
6. Type `run` to play the game !, press _escape_ to exit the game and return back to the terminal.
7. Hope you enjoyed !

* More guides are being worked on.
