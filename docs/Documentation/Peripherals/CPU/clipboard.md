# CPU.clipboard
---

Read or write to/from the clipboard.

---

* **Available since:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Read the clipboard content:
---

```lua
local content = CPU.clipboard()
```


---
#### Returns
---

* **content (string):** The clipboard content.

---

# 2. Set the clipboard content:
---

```lua
CPU.clipboard(content)
```


---
#### Arguments
---

* **content (string, number):** The new clipboard content.

---