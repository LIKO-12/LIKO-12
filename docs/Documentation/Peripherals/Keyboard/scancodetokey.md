# Keyboard.scancodetokey
---

Gets the key corresponding to the given hardware scancode.

Unlike key constants, Scancodes are keyboard layout-independent. For example the scancode "w" will be generated if the key in the same place as the "w" key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

Scancodes are useful for creating default controls that have the same physical locations on on all systems.

Check [Enums/Scancodes](/Documentation/Enums/Scancodes.md) and [Enums/KeyConstants](/Documentation/Enums/KeyConstants.md).

---

* **Available since:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local key = Keyboard.scancodetokey(scancode)
```

---
### Arguments
---

* **scancode (string):** The scancode to get the key from.


---
### Returns
---

* **key (string):** The key corresponding to the given scancode, or "unknown" if the scancode doesn't map to a KeyConstant on the current system.

