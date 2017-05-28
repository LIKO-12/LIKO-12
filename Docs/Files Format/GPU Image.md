## The LIKO-12 [GPU Image](../GPU/image.md) Format:

---

The image data is usually saved as .lk12 file, you'll have to use hdd.read and pass the data to [GPU.image](../GPU/image.md) or [GPU.imagedata](../GPU/imagedata.md) inorder to load.

---

The LIKO-12's GPU image format is so simple, it's consisted of a **header**, and a **data body**:

---

## 1. The header:

---

The header is only one line and pretty simple:
```text
LK12;GPUIMG:%(w)x%(h);
```

The **%(w)** and **%(h)** are replaced with the image dimensions.

It's also possible to add a newline after the header end.

---

#### Example:

```text
LK12;GPUIMG;8x8;
```

---

## 2. The data body:

---

It contains the image data, it's made of hex digits, so every hex digit represents a color id:
```text
Hex: 0123456789  a  b  c  d  e  f
Dec: 0123456789 10 11 12 13 14 15
```

It starts from the top left pixel and then going right in each row (horizental line), and for more readablity there is a newline at each row start.

---

#### Example:

(The top left pixel is color 10, the bottom right is 12, rest are 11)

```text
LK12;GPUIMG;4x4;
9aaa
aaaa
aaaa
aaab
```

(Or written in one line)
```text
LK12;GPUIMG;4x4;9aaaaaaaaaaaaaab
```

---

**Important Note**: do **NOT** add any characters other than hex digits and new lines ! Or the GPU will crash when loading the image !