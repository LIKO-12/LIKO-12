This function is called everytime a key is pressed.

When the button is held for a little bit longer, this function will be called multiple times with `isrepeat` as true.

---

**Important Note:** Besure to call [Controls("keyboard")](../DiskOS API/Controls.md) in the first line of the game !

**Another Note:** The keyboard on android can be closed by the user, so to reshow it you should call `textinput(true)` in [_touchpressed](./_touchpressed.md) callback.

---

#### Syntax:
```lua
function _keypressed(key,scancode,isrepeat)
  --Do something here
end
```

---

#### Arguments:

* **key (String)**: The pressed button, check [KeyConstants Enum](../Enums/KeyConstants.md).
* **scancode (String)**: The scancode representing the pressed key, check check [Scancodes Enum](../Enums/Scancodes.md).
* **isrepeat (Boolean)**: Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.