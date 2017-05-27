Swaps color in palette with another color used by draw functions.

### Syntax
    pal([a],[b],[mode])

### Parameters

* If left empty: Resets palette to default.
* a: Color to replace. (If only a is provided then it will be reset to default)
* b: Color which will replace a.
* mode: 1 affects all GPU functions except images, 2 only affects images, default affects both.