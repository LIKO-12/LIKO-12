![LIKO-12](Header_Logo.png)

## Welcome to the official LIKO-12 Documentation !

**Please note that the documentation is not finished and it's still being written !**

---

## Guides:

---

* [Installation Guide](Installation Guide.md)
* [Getting Started](Getting Started.md)
* [Keyboard Shortcuts](Keyboard Shortcuts.md)
* [Using external code editor](Using external code editor.md)
* [Third-Party Libraries](Third-Party Libraries.md)
* [The MAP API](The MAP API.md)

---

## About:

LIKO-12 is an _open source_ **fantasy computer** completely written in the Lua programming language where you can make, play and share tiny retro-looking games and programs.

The LIKO-12 fantasy computer comes with a default, fully customizable, DOS-like operating system installed, called DiskOS, which provides an environment with basic command line programs and visual game editors.

Games are stored as disk files that can be saved, shared and uploaded to pastebin via the built-in program.

## What it has:

### The BIOS POST Screen:

When you start LIKO-12, the BIOS POST screen will showup displaying LIKO-12 specs and the virtual harddisks usage.

![BIOS_POST](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/BIOS_POST.png)

You can also access the setup screen by pressing delete on desktop, or back on android, but currently it displays a "Comming Soon" message.

### DiskOS Installer:

When you boot LIKO-12 for the first time, an scrolling display would be shown installing DiskOS, the default LIKO-12 operating system.

![DiskOS_Installer](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/DiskOS_Installer.png)

It will only run a single time, and wont run again at next boots, except when an update happens, where a 'DiskOS Updater' would be shown, and the process would be much faster in this case, as it only updates the necessary files.

### DiskOS Greeting and Terminal:

Once the Installation Completes, DiskOS will boot up, the LIKO-12 opereating system.

![DiskOS_Prompt](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/DiskOS_Prompt.gif)

Here you can type common commands to do common tasks, like `cd` (Change Directory), `ls` (List files), `load` (Load a Game/Demo), `run` (Run the loaded Game/Demo), `reboot` (Reboot LIKO-12), `shutdown`/`exit` (Exit LIKO-12), And more in the documentation....

You would also notice the terminal path pointing to `D:/`, and you can also enter the C drive which has the operating system files by typing `cd C:`, but don't worry, those drives are not related to your real-computer drives at all, they are already sandbox with a space limit.

### The Editors:

LIKO-12 comes with it's own editors for making games, already setup for you, you can easily access them by pressing `escape` (esc) / back on Android to open them, and later you can press `esc`/`back` (Android) to return back into the terminal.

#### Code editor:

![Code_Editor](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/Code_Editor.png)

Here you write the code for your game, LIKO-12 uses Lua for everything, for DiskOS, for the Engine, and for Games !

#### Sprites editor:

Here you can edit your game sprites, 8x8 each sprite, 384 sprites total.

![Sprite_Editor](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/Sprite_Editor.png)

#### Map editor:

Here you can edit the map of your game, I know the editor is very hard to use, but I'm going to provide an update with a completely redesigned map editor.

![Map_Editor](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/Map_Editor.png)

#### SFX editor % Music editor:

![WIP_Editor](https://github.com/RamiLego4Game/LIKO-12/raw/master/Extra/Readme-Screenshots/WIP_Editor.png)

Those editors hasn't been made yet, but they are really comming soon (they are currently under work)

---

## The Fantasy Computer Specifications:

| Spec  | Info                                |
| ----- | ----------------------------------- |
| CPU   | LuaJIT (Lua 5.1)                    |
| GPU   | 192x128 4-Bit Screen                |
| Map   | 144x128 Cell (255 Tile)             |
| HDD   | 2x 25mb drives                      |
| Input | Keyboard, Mouse, Touch, and Gamepad |

---

## Social links:

| Type           | Link                                                      |
| -------------- | --------------------------------------------------------- |
| Itch.io        | [LIKO-12](https://ramilego4game.itch.io/liko12)           |
| Documentation  | [ReadTheDocs](http://liko-12.readthedocs.io)              |
| Twitter        | [@RamiLego4Game](https://twitter.com/ramilego4game)       |
| Discord (Chat) | [LIKO-12](https://discord.gg/GDtHrsJ)                     |
| Trello Board   | [LIKO-12](https://trello.com/b/bHo8Y9sx/liko-12)          |
| Github         | [LIKO-12](https://github.com/RamiLego4Game/LIKO-12)       |
| Email          | [ramilego4game@gmail.com](emailto:ramilego4game@gmail.com)|

---

## Releases/Downloads Page: 

* **Itch.io:** https://ramilego4game.itch.io/liko12
* **Github:** https://github.com/RamiLego4Game/LIKO-12/releases/
* **Nightly-Builds:** https://ramilego4game.github.io/LIKO-12-Nightly/