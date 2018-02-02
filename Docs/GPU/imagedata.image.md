Converts the imagedata to an image, which can be drawn to the screen.

**Note**: This function is slow if called repeatly, unlike [image:data()](image.data).

---

#### Syntax:
```lua
img = imgdata:image() --Don't forget the ':'
```

---

#### Returns:

* **img ([GPUImage](image.md))**: The created image object.

---

##### See also:

* [imagedata:refresh()](imagedata.refresh.md)