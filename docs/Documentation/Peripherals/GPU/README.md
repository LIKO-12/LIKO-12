# GPU - The Graphics Processing Unit
---

It's the strongest peripheral in LIKO-12, and the biggest file also, it's responsible for creating the window and doing all the drawing operations.

---

* **Version:** 1.0.0
* **Available since LIKO-12:** v0.6.0
* **Last updated in LIKO-12:** v0.8.0

---
### Methods
---
* [cam](/Documentation/Peripherals/GPU/cam.md): Transforms the drawing operations.
* [circle](/Documentation/Peripherals/GPU/circle.md): Draws a circle on the screen.
* [clearMatrixStack](/Documentation/Peripherals/GPU/clearMatrixStack.md): Clears the matrix stack (By calling `popMatrix()`).
* [clear](/Documentation/Peripherals/GPU/clear.md): Clears the screen and fills it with a specific color, useful when clearing the screen for a new frame.
* [clip](/Documentation/Peripherals/GPU/clip.md): Sets the region that the GPU can draw on.
* [colorPalette](/Documentation/Peripherals/GPU/colorPalette.md): Allows you to read and modify the real RGBA values of a color in the palette.
* [color](/Documentation/Peripherals/GPU/color.md): Set's the current active color.
* [cursor](/Documentation/Peripherals/GPU/cursor.md): Sets the current active mouse cursor, or creates a new one.
* [ellipse](/Documentation/Peripherals/GPU/ellipse.md): Draws an ellipse on the screen.
* [endGifRecording](/Documentation/Peripherals/GPU/endGifRecording.md): End LIKO-12 screen Gif recording by code.
* [flip](/Documentation/Peripherals/GPU/flip.md): Waits till the screen is applied and shown to the user, helpful when doing some loading operations.
* [fontHeight](/Documentation/Peripherals/GPU/fontHeight.md): Returns height of the font character in pixels.
* [fontSize](/Documentation/Peripherals/GPU/fontSize.md): Returns size of the font character in pixels.
* [fontWidth](/Documentation/Peripherals/GPU/fontWidth.md): Returns width of the font character in pixels.
* [getLabelImage](/Documentation/Peripherals/GPU/getLabelImage.md): Returns the imagedata object of LabelImage, which can be capture by pressing F6, It will automatically update to the latest capture.
* [getMPos](/Documentation/Peripherals/GPU/getMPos.md): Gets position of the mouse.
* [image](/Documentation/Peripherals/GPU/image.md): Creats a new image that can be used for drawing.
* [imagedata](/Documentation/Peripherals/GPU/imagedata.md): Creates a new imagedata object, which can be used for images processing (Set pixels, Get Pixels, encode, export, etc...).
* [isGifRecording](/Documentation/Peripherals/GPU/isGifRecording.md): Tells if the GPU is recording the screen or not.
* [isMDown](/Documentation/Peripherals/GPU/isMDown.md): Checks if a mouse button is down.
* [line](/Documentation/Peripherals/GPU/line.md): Draws line(s) on the screen.
* [pal](/Documentation/Peripherals/GPU/pal.md): Maps a color in the palette to another color.
* [palt](/Documentation/Peripherals/GPU/palt.md): Makes a specific color transparent or not, by default the color 0 is transparent.
* [pauseGifRecording](/Documentation/Peripherals/GPU/pauseGifRecording.md): Pause LIKO-12 screen Gif recording by code.
* [point](/Documentation/Peripherals/GPU/point.md): Draws point(s) on the screen.
* [polygon](/Documentation/Peripherals/GPU/polygon.md): Draws a polygon on the screen.
* [popColor](/Documentation/Peripherals/GPU/popColor.md): Pops the last active color from the ColorStack.
* [popMatrix](/Documentation/Peripherals/GPU/popMatrix.md): Pops the last cam transformations from the MatrixStack.
* [popPalette](/Documentation/Peripherals/GPU/popPalette.md): Pop the last color mapping and transparent colors list from the palettes stack.
* [printBackspace](/Documentation/Peripherals/GPU/printBackspace.md): Deletes the last printed character via the 3rd and 4th variants of `print()`, and it updates the cursor position.
* [printCursor](/Documentation/Peripherals/GPU/printCursor.md): Changes the print cursor position used by `print()` in the grid variant.
* [print](/Documentation/Peripherals/GPU/print.md): Prints text to the screen, uses the current active color.
* [pushColor](/Documentation/Peripherals/GPU/pushColor.md): Pushes the current active color to the ColorStack.
* [pushMatrix](/Documentation/Peripherals/GPU/pushMatrix.md): Pushes the current active camera transformations to the MatrixStack.
* [pushPalette](/Documentation/Peripherals/GPU/pushPalette.md): Pushes the current color mapping and transparent colors list to the palettes stack.
* [quad](/Documentation/Peripherals/GPU/quad.md): Creates a new quad.
* [rect](/Documentation/Peripherals/GPU/rect.md): Draws a rectangle on the screen.
* [screenHeight](/Documentation/Peripherals/GPU/screenHeight.md): Returns the height of the screen.
* [screenSize](/Documentation/Peripherals/GPU/screenSize.md): Returns the dimensions of the screen.
* [screenWidth](/Documentation/Peripherals/GPU/screenWidth.md): Returns the width of the screen.
* [screenshot](/Documentation/Peripherals/GPU/screenshot.md): Takes a screenshot of the canvas (without the cursor), and returns its imagedata.
* [startGifRecording](/Documentation/Peripherals/GPU/startGifRecording.md): Start LIKO-12 screen Gif recording by code.
* [termHeight](/Documentation/Peripherals/GPU/termHeight.md): Returns height of the terminal in characters.
* [termSize](/Documentation/Peripherals/GPU/termSize.md): Returns size of the terminal in characters.
* [termWidth](/Documentation/Peripherals/GPU/termWidth.md): Returns width of the terminal in characters.
* [triangle](/Documentation/Peripherals/GPU/triangle.md): Draws a triangle on the screen.
* [wrapText](/Documentation/Peripherals/GPU/wrapText.md): Gets formatting information for text, given a wrap limit.

---
### OS Methods
---
!> Those methods are not available for games.
* [_systemMessage](/Documentation/Peripherals/GPU/_systemMessage.md): Shows a system message: A single line message at the bottom of the screen.
