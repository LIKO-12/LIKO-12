Allows you to read and modify the real RGBA values of a color in the palette.

---

## Syntax:

---

### 1. Read the RGB values of a color.

---

#### Syntax:
```lua
r,g,b = colorPalette(id)
```

---

#### Arguments:

* **<id\> (Number)**: The color id.

---

#### Returns:

* **r (Number)**: The red channel value [0-255].
* **g (Number)**: The green channel value [0-255].
* **b (Number)**: The blue channel value [0-255].

---

### 2. Set the RGB values of a color.

---

#### Syntax:
```lua
colorPalette(id,r,g,b)
```

---

#### Arguments:

* **<id\> (Number)**: The color id.
* **<r\> (Number)**: The red channel value [0-255].
* **<g\> (Number)**: The green channel value [0-255].
* **<b\> (Number)**: The blue channel value [0-255].

---

3. Reset the palette colors to their defaults (PICO-8 Palette):

---

#### Syntax:
```lua
colorPalette()
```
