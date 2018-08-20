Enables or disables key repeat. It is disabled by default.

The interval between repeats depends on the user's system settings.

**Note:** It's better to do `if isrepeat then return true end` than calling this function.

---

## 1. Disable/Enable key repeat.

---

### Syntax:
```lua
keyrepeat(state)
```

---

### Arguments:

* **<state\> (Boolean)**: Whether repeat keypress events should be enabled when a key is held down.

---

## 2. Get the current key repeat state.

---

### Syntax:
```lua
state = keyrepeat()
```

---

### Returns:

* **state (Boolean)**: Whether repeat keypress events should be enabled when a key is held down.