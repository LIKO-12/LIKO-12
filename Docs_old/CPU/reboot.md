Reboot LIKO-12

---

## 1. Soft Reboot:

---

Soft reboots LIKO-12 by doing an internal trick to reload the BIOS and bootup again, will leave some garbage that will be cleaned automatically by the Lua garbage collector.

---

### Syntax:
```lua
reboot()
```

---

## 2. Hard Reboot:

---

Hard reboots LIKO-12 by reinitializing the LÖVE engine, will clear the whole Lua state, and re-create the window.

---

### Syntax:
```lua
reboot(true)
```

---

##### See also:

* [shutdown()](shutdown.md)