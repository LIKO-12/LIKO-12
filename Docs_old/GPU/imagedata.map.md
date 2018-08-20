Transform an image by applying a function to every pixel.

---

## Usage:

---

#### Syntax:
```lua
imgdata:map(f)
```

---

#### Arguments:

* **<f\> (Function)**: The callback function.

---

## The callback function:

---

```lua
imgdata:map(function(x,y,c)
  return c
end)
```

The function that's passed as an argument will be called for every pixel in the image, starting with the top-left one, and going in horizental lines.

There are 3 variables passed to it:

* **x (Number)**: The x position of the pixel.
* **y (Number)**: The y position of the pixel.
* **c (Number)**: The color of the pixel.

And the function can return the new pixel color, otherwise the pixel color will stay the same.