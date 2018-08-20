This is more of a system event, it's better to not look at it, just use btnp, or btn.

---

This function is called when a gamepad button in the touch controls (On mobile devices), changes it's state (get's pressed or released).

---

#### Syntax:
```lua
function _touchcontrol(state,id)

end
```

---

#### Arguments:

* **state (Boolean)**: The new state of the button, true for pressed, false for released.
* **id (Number)**: The gamepad button that changed it's state, can be from 1 to 7.