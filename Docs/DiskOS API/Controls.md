This functions tells DiskOS what kind of input this game is using, call this at the first line of your game.

If you are going to use the gamepad input, then it's safe to not call this function.

---

Currently there are 4 types of input:

1. **Gamepad (Default)**: The 7 buttons gamepad for 2 players, supports running the game on Android.

![Gamepad](Controller.png)

```
Default Controllers Keysmap:

Player 1: Left,Right,Up,Down, Z,X, C.
Player 2: S,F,E,D, Tab,Q, W.

Note: The keymap can be changed by the user via the 'keymap' program.
```

2. **Keyboard**: All keyboard keys, not Android-friendly !
3. **mouse**: If the game only uses mouse, Android may have a virtual touchpad in the future.
4. **touch**: When the game requires multi-fingers input.
5. **none**: If the game is just a fancy animation demo.

---

#### Syntax:
```lua
Controls(ctype)
```

---

#### Arguments:

* **[ctype] (String) ("gamepad")**: The input type, can be `gamepad` (Default), `keyboard`, `mouse`, `touch`, `none`.