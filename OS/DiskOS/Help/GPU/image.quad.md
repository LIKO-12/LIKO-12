Creats a new quad.

It's the same of [GPU.quad()](quad.md), But it passes the image dimensions automatically.

---

#### Syntax:
```lua
q = img:quad(x,y,w,h)
```

---

#### Arguments:

* **<x\> (Number)**: The x coord of the quad's top-left corner.
* **<y\> (Number)**: The y coord of the quad's top-left corner.
* **[w] (img:width) (Number)**: The width of the quad, defaults to the image width.
* **[h] (img:height) (Number)**: The height of the quad, defaults to the image height.

---

#### Returns:

* **q ([GPUQuad](quad.md))**: The created quad.