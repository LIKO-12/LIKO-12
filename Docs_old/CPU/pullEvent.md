Pulls an event from the events stack.

This function is used internally by DiskOS to run the default event loop, which calls the callback functions that start by `_` like `_update` and `_mousepressed`, etc..

Events in LIKO-12 may be pulled directly, or pulled from a stack if there are already, the stack may fill up when [CPU.sleep](sleep.md) or [GPU.flip](../GPU/flip.md) are called.

---

### Syntax:
```lua
event, a,b,c,d,e,f = pullEvent()
```

---

### Returns:

* **event (String)**: The event name, can be any of the callbacks names without the "_" at the start.
* **a,b,c,d,e,f (Any)**: The arguments of the event.

---

##### See also:

* [rawPullEvent()](rawPullEvent.md)
* [triggerEvent()](triggerEvent.md)
* [clearEStack()](clearEStack.md)