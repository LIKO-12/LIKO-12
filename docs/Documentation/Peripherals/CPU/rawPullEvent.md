# CPU.rawPullEvent
---

Pulls a new event directly, returns it and stores it in the events stack, used by DiskOS to handle the `escape` key.

---

* **Available since:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local event, a, b, c, d, e, f = CPU.rawPullEvent()
```

---
### Returns
---

* **event (string):** The event name, can be any of the callbacks names without the "_" at the start.
* **a (any):** First argument.
* **b (any):** Second argument.
* **c (any):** Third argument.
* **d (any):** Forth argument.
* **e (any):** Fifth argument.
* **f (any):** Sixth argument.

