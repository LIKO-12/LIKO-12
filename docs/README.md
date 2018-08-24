
[![Release Badge](https://img.shields.io/github/release/RamiLego4Game/LIKO-12/all.svg)](https://github.com/RamiLego4Game/LIKO-12/releases)
[![Downloads](https://img.shields.io/github/downloads/RamiLego4Game/LIKO-12/total.svg)](https://github.com/RamiLego4Game/LIKO-12/releases)
[![Commits Badge](https://img.shields.io/github/commits-since/RamiLego4Game/LIKO-12/latest.svg)](https://github.com/RamiLego4Game/LIKO-12/commits/master)
[![Nightly Build 0.9.0](https://img.shields.io/badge/nightly_builds-v0.9.0-orange.svg)](https://ramilego4game.github.io/LIKO-12-Nightly/)
[![Donate Badge](https://img.shields.io/badge/%24-Donate-ff69b4.svg)](Donate)
[![License Badge](https://img.shields.io/badge/License-MIT-blue.svg)](?id=license)
[![Stars Badge](https://img.shields.io/github/stars/RamiLego4Game/LIKO-12.svg?style=flat&label=Stars)](https://github.com/RamiLego4Game/LIKO-12)

---

# About

---

LIKO-12 is a fantasy computer that you can use to make, play and share tiny retro-looking games and programs.

This fantasy computer comes with a default, fully customizable, DOS-like operating system installed, called DiskOS,
which provides and environment with basic command line programs and visual game editors.

The created games are stored as disk files that can be saved, shared and played by friends and others.

---

# Specifications

---

| Spec  | Info                                 |
| ----- | ------------------------------------ |
| CPU   | LuaJIT (Lua 5.1)                     |
| GPU   | 192x128 4-Bit Screen                 |
| Map   | 144x128 Cell (255 Tiles)             |
| HDD   | 2x 50mb drives                       |
| Input | Keyboard, Mouse, Touch, and Gamepads |

---

# Features

---

- Uses LuaJIT, much faster than vanilla Lua, but has Lua 5.1 API.
- Has a virtual drives system, with size limitation, so a miscellaneous script won't fill your system drive.
- The games has a secure environment (_I hope_), so they won't be able to do miscellaneous things.
- Comes with integrated editors, start creating games out of the box:
  - Code editor:
    - Lua syntax highlighter.
    - Highlights API functions.
    - Has clipboard support.
  - Sprite editor:
    - 192x128 Sprite-sheet, sliced into 4 banks.
    - Edits the sheet as 8x8, 16x16 or 32x32 sprites.
    - Each 8x8 sprite has a 1 byte flags (each bit acts as a flag).
    - Has clipboard support.
    - Clipboard compatible with [TIC-80](https://tic.computer/) (another fantasy computer), and supports pasting sprites from [PICO-8](https://www.lexaloffle.com/pico-8.php) (another fantasy console).
  - Map editor:
    - Has a compact design.
    - Shows a grid with the room size (A room is the space for filling the whole LIKO-12 screen with tiles).
  - SFX editor:
    - Has 64 sfx slot available.
    - Each sfx is made of 32 notes.
    - The sfx playing speed is modifiable.
    - Supports 6 waveforms (sine, square, pulse, sawtooth, triangle, noise).
  
---

# Screenshots

---

### The code editor
![Code_Editor](/_media/Code_Editor.png)

---

### The sprite editor

![Sprite_Editor](/_media/Sprite_Editor.png)

---

### The map editor
![Map_Editor](/_media/Map_Editor.png)

---

### The SFX editor
![SFX_Editor](/_media/SFX_Editor.png)

---

### The system prompt
![DiskOS_Prompt](/_media/DiskOS_Prompt.gif)

---

### The BIOS POST screen
![BIOS_POST](/_media/BIOS_POST.png)

---

### The BIOS setup screen
![BIOS_Setup](/_media/BIOS_Setup.png)

---

### The operating system installation screen
![DiskOS_Installer](/_media/DiskOS_Installer.png)

---

# License

---

[license](/LICENSE ':include :type=code')