Converts the imagedata to an image, which can be drawn to the screen.

**Note**: This function is slow if called repeatly, unlike [image:data()](image.data).

**Note 2**: [image:refresh()](image.refresh.md) will reload it's content from it's source ImageData.

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

* [image:refresh()](image.refresh.md)