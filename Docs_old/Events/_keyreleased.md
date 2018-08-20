This function is called everytime a key is released.

**Important Note:** Besure to call [Controls("keyboard")](../DiskOS API/Controls.md) in the first line of the game !

---

**Another Note:** The keyboard on android can be closed by the user, so to reshow it you should call `textinput(true)` in [_touchpressed](./_touchpressed.md) callback.

---

#### Syntax:
```lua
function _keyreleased(key,scancode)
  --Do something here
end
```

---

#### Arguments:

* **key (String)**: The released button, check [KeyConstants Enum](../Enums/KeyConstants.md).
* **scancode (String)**: The scancode representing the released key, check check [Scancodes Enum](../Enums/Scancodes.md).