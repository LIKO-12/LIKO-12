Gets formatting information for text, given a wrap limit.

This function accounts for newlines correctly (i.e. '\n').

---

#### Syntax:
```lua
width, wrappedText = wrapText(text, wraplimit)
```

---

#### Arguments:

* **<text\> (String)**: The text that will be wrapped.
* **<wraplimit\> (Number)**: The maximum width in pixels of each line that text is allowed before wrapping.

---

#### Returns:

* **width (String)**: The maximum width of the wrapped text.
* **wrappedText (Table)**: A sequence containing each line of text that was wrapped.

---

##### See also:

* [print()](print.md)
* [printBackspace()](printBackspace.md)
* [printCursor()](printCursor.md)