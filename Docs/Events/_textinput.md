Called when text has been entered by the user. For example if shift-2 is pressed on an American keyboard layout, the text "@" will be generated.

textinput is disabled by default; call `textinput(true)` to enable it.

---

#### Syntax:
```lua
function _draw(text)
  --Do something here
end
```

---

#### Arguments:

* **text(String)**: The inputted text, with modifier key actions applied.