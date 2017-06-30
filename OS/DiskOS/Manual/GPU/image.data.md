Returns the imagedata object of this image, which can be used to set and get pixels of the image.

**Note**: This function is fast, unlike [imagedata:image()](imagedata.image).

---

#### Syntax:
```lua
imgdata = img:data() --Don't forget the ':'
```

---

#### Returns:

* **imgdata ([GPUImageData](imagedata.md))**: The imagedata object of this image.