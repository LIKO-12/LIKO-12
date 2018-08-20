Called when text has been entered by the user. For example if shift-2 is pressed on an American keyboard layout, the text "@" will be generated.

**Important Note:** Besure to call [Controls("keyboard")](../DiskOS API/Controls.md) in the first line of the game !

---

**Another Note:** The keyboard on android can be closed by the user, so to reshow it you should call `textinput(true)` in [_touchpressed](./_touchpressed.md) callback.

---

#### Syntax:
```lua
function _draw(text)
  --Do something here
end
```

---

#### Arguments:

* **text(String)**: The inputted text, with modifier key actions applied.