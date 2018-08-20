# Keyboard.textinput
---

Enables the text input, and shows the onscreen keyboard for the mobile users.

---

* **Available since:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Disable/Enable textinput:
---

```lua
Keyboard.textinput(state)
```


---
#### Arguments
---

* **state (boolean):** True to enable the input, False to disable it.

---

# 2. Get the current textinput state:
---

```lua
local state = Keyboard.textinput()
```


---
#### Returns
---

* **state (boolean):** True if the textinput is enabled, false is the text input is disabled.

---