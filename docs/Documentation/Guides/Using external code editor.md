Many people would like to use an external code editor, and they have reasons for that, that's why I added a special way for external code editors usage.

Editing the .lk12 file is not a good choice, because you will have to reload it each time you edit it, and you can over-write it by a mistake.

---

## 1. Moving your current code into a .lua file

---

You can simply do this by typing:

```
save mygame --code
```

In the terminal, .lua extension will be automatically added.

---

## 2. Clear the code from the internal code editor

---

Press Ctrl-A, and then Backspace.

LIKO-12 may lag for a while when selecting everything, depending on how big your code is.

---

## 3. Call dofile in the code editor

---

Now in the code editor, after clearing it, type:

```lua
dofile("D:/mygame.lua")
```

You may also call it for multiple files.

---

This way, you won't have to reload the .lk12 file each time editing your code, as the code files will be loaded when running the game.

---

## 4. Putting the code back into the code editor

---

When you want to share the game, you will have to put all the code back into the code editor, you can do this by editing .lk12 file, or pasting them using the internal code editor (may be slow).

In the same order they are called at.

Note that the local variables will be merged between them.

---

That's it.

Goodluck !