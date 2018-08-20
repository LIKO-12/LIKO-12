# CPU.pullEvent
---

Pulls an event from the events stack.

This function is used internally by DiskOS to run the default event loop, which calls the callback functions that start by `_` like `_update` and `_mousepressed`, etc..

Events in LIKO-12 may be pulled directly, or pulled from a stack if there are already, the stack may fill up when CPU `sleep()` or GPU `flip()` are called.

---

* **Available since:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local event, a, b, c, d, e, f = CPU.pullEvent()
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

