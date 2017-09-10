Pulls a new event directly, returns it and stores it in the events stack, used by DiskOS to handle the `escape` key.

---

### Syntax:
```lua
event, a,b,c,d,e,f = rawPullEvent()
```

---

### Returns:

* **event (String)**: The event name, can be any of the callbacks names without the "_" at the start.
* **a,b,c,d,e,f (Any)**: The arguments of the event.

---

##### See also:

* [pullEvent()](pullEvent.md)
* [triggerEvent()](triggerEvent.md)
* [clearEStack()](clearEStack.md)