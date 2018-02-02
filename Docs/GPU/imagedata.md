Creates a new GPUImageData object, which can be used for images processing (Set pixels, Get Pixels, encode, export, etc...).

---

## Usage:

---

### 1. Create from a string in [LK12 GPUImage format](../Files Format/GPU Image.md):

---

#### Syntax:
```lua
imgdata = imagedata(data)
```

---

#### Arguments:

* **<data\> (String)**: The image data, must be in [LK12 GPUImage format](../Files Format/GPU Image.md).

---

#### Returns:

* **imgdata (GPUImageData)**: The created imagedata object.

---

### 2. Create from png binary string:

---

#### Syntax:
```lua
imgdata = imagedata(data)
```

---

#### Arguments:

* **<data\> (String)**: The image data, png binary string.

---

**Note**: All transparent pixels and all colors that arn't from the palette will be loaded as black !

---

#### Returns:

* **imgdata (GPUImageData)**: The created imagedata object.

---

### 3. Create from an [GPUImage](image.md) object:

---

#### Syntax:
```lua
imgdata = img:data()
```

#### Returns:

* **imgdata (GPUImageData)**: The created imagedata object.

---

### 4. Create a new blank imagedata:

---

#### Syntax:
```lua
imgdata = imagedata(w,h)
```

---

#### Arguments:

* **<w\> (Number)**: The imagedata width in pixels.
* **<h\> (Number)**: The imagedata height in pixels.

---

#### Returns:

* **imgdata (GPUImageData)**: The created imagedata object.

---

## The imagedata object functions:

---

* [**imgdata:size()**](imagedata.size.md)
* [**imgdata:width()**](imagedata.width.md)
* [**imgdata:height()**](imagedata.height.md)
* [**imgdata:image()**](imagedata.image.md)
* [**imgdata:setPixel()**](imagedata.setPixel.md)
* [**imgdata:getPixel()**](imagedata.getPixel.md)
* [**imgdata:map()**](imagedata.map.md)
* [**imgdata:enlarge()**](imagedata.enlarge.md)
* [**imgdata:quad()**](imagedata.quad.md)
* [**imgdata:paste()**](imagedata.paste.md)
* [**imgdata:encode()**](imagedata.encode.md)
* [**imgdata:export()**](imagedata.export.md)
* [**imgdata:exportOpaque()**](imagedata.exportOpaque.md)
* [**imgdata:type()**](imagedata.type.md)
* [**imgdata:typeOf()**](imagedata.typeOf.md)

---

##### See also:

* [image()](image.md)
* [screenshot()](screenshot.md)