# BIOS.getVersion
---

Returns LIKO-12's Version.

---

* **Available since:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0
* **Last updated in:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0

---

```lua
local LIKO_Version, LIKO_Old = BIOS.getVersion()
```

---
### Returns
---

* **LIKO_Version (string):** Current LIKO-12's version string (ex: `0.9.0_DEV`).
* **LIKO_Old (string, nil):** The previous installed LIKO-12's version string (ex: `0.8.0_PRE`).


---

!> The `LIKO_Old` value is only provided when LIKO-12 boots for the __first time__ with the new version.