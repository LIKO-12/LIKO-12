Checks whether an object is of a certain type. If the object has the type with the specified name in its hierarchy, this function will return true.

For GPUImg, it returns true for the folowing types: 'GPU', 'image', 'GPU.image', 'LK12'

---

#### Syntax:
```lua
bool = img:typeOf(t)
```

---

#### Argumnets:

* **<t\> (String)**: The name of the type to check for.

---

#### Returns:

* **bool (Boolean)**: True if the object is of the specified type, false otherwise.