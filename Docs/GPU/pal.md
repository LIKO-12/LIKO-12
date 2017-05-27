Swaps color in palette with another color used by draw functions.

### Syntax
    pal([a],[b],[mode])

### Parameters

* If left empty: Resets palette to default.
* a: Color to replace. (If only a is provided then it will be reset to default)
* b: Color which will replace a.
* mode: 0 affects all GPU functions except images, 1 only affects images, if left empty - affects both.