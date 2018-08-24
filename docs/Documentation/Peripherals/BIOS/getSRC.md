# BIOS.getSRC
---

Returns `LIKO-12_Source.love` data.

---

?> `LIKO-12_Source.love` is created at the first boot whenever a different LIKO-12 version is used, with the message `Generating internal file...` shown.

---

* **Available since:** _BIOS:_ v1.18.2, _LIKO-12_: v0.9.0
* **Last updated in:** _BIOS:_ v1.18.2, _LIKO-12_: v0.9.0

---

```lua
local LIKO_SRC, err = BIOS.getSRC()
```

---
### Returns
---

* **LIKO_SRC (string, boolean):** The file data of LIKO-12's source code .love file.
* **err (string, nil):** The failure reason if `LIKO_SRC` was `false`.

