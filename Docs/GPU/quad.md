Creates a new quad.

---

Quads can be used to select a part of an image to draw. In this way, one large images atlas (sheet) can be loaded, and then split up into sub-images.

---

## Usage:

---

#### Syntax:
```lua
q = quad(x,y, w,h, sw,sh)
```

---

#### Arguments:

* **<x\> (Number)**: The x coord of the quad's top-left corner.
* **<y\> (Number)**: The y coord of the quad's top-left corner.
* **<w\> (Number)**: The width of the quad.
* **<h\> (Number)**: The height of the quad.
* **<sw\> (Number)**: The width of the reference image.
* **<sh\> (Number)**: The height of the reference image.

---

#### Returns:

* **q (GPUQuad)**: The created quad.

---

## The quad object functions:

---

* [**quad:getTextureDimensions()**](quad.getTextureDimensions.md)
* [**quad:getViewport()**](quad.getViewport.md)
* [**quad:setViewport()**](quad.setViewport.md)
