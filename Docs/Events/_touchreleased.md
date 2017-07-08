This function is called when the touch screen stops being touched.

---

#### Syntax:
```lua
function _touchreleased(id,x,y,dx,dy,p)

end
```

---

#### Arguments:

* **id (Number)**: The touch id.
* **x (Number)**: The X coord of the touch.
* **y (Number)**: The Y coord of the touch.
* **dx (Number)**: The delta-x of the touch.
* **dy (Number)**: The delta-y of the touch.
* **p (Number)**: The pressure of the touch (Only on drawing tablets, 1 on any normal device).