# GPU.wrapText
---

Gets formatting information for text, given a wrap limit.

This function accounts for newlines correctly (i.e. '\n').

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local width, wrappedText = GPU.wrapText(text, wraplimit)
```

---
### Arguments
---

* **text (string):** The text that will be wrapped.
* **wraplimit (number):** The maximum width in pixels of each line that text is allowed before wrapping.


---
### Returns
---

* **width (string):** The maximum width of the wrapped text.
* **wrappedText (table):** A sequence containing each line of text that was wrapped.

