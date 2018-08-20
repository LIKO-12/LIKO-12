# Keyboard.keytoscancode
---

Gets the hardware scancode corresponding to the given key.

Unlike key constants, Scancodes are keyboard layout-independent. For example the scancode "w" will be generated if the key in the same place as the "w" key on an American keyboard is pressed, no matter what the key is labelled or what the user's operating system settings are.

Scancodes are useful for creating default controls that have the same physical locations on on all systems.

Check [Enums/Scancodes](/Documentation/Enums/Scancodes.md) and [Enums/KeyConstants](/Documentation/Enums/KeyConstants.md).

---

* **Available since:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local scancode = Keyboard.keytoscancode(nil)
```

---
### Arguments
---

* **`nil` (string):** The key to get the scancode from.


---
### Returns
---

* **scancode (string):** The scancode corresponding to the given key, or "unknown" if the given key has no known physical representation on the current system.

