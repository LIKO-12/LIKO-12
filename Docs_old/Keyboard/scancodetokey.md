Gets the key corresponding to the given hardware scancode.

Unlike key constants, Scancodes are keyboard layout-independent. For example the scancode "w" will be generated if the key in the same place as the "w" key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

Scancodes are useful for creating default controls that have the same physical locations on on all systems.

Check [Enums/Scancodes](../Enums/Scancodes.md) and [Enums/KeyConstants](../Enums/KeyConstants.md).

---

### Syntax:
```lua
key = scancodetokey(scancode)
```

---

### Arguments:

* **<scancode\> (String)**: The scancode to get the key from.

---

### Returns:

* **key (String)**: The key corresponding to the given scancode, or "unknown" if the scancode doesn't map to a KeyConstant on the current system.