Loads the contents of a Lua script as a function.

---

### Syntax:
```lua
file = fs.load("/file.lua")
```

---

### Returns:
* **file**: Loaded script
If there was an error in the function:
* **ok**: First item returned from pcall
* **err**: Second item returned from pcall
If there was an error in pcall:
* **ok**: Second item returned from pcall
* **err**: Third item returned from pcall