/// <reference path="./image.ts" />

declare type PixelFunction = (this: void, x: number, y: number, color: number) => number;

declare interface ImageData {
    /**
     * Gets the width of the imageData.
     *
     * @return The width of the image in pixels.
     */
    getWidth(this: ImageData): number;

    /**
     * Gets the height of the imageData.
     *
     * @return The height of the image in pixels.
     */
    getHeight(this: ImageData): number;

    /**
     * Gets the color of a pixel in the imageData.
     *
     * @param x The X coordinates of the pixel.
     * @param y The Y coordinates of the pixel.
     * @return The color of the pixel.
     */
    getPixel(this: ImageData, x: number, y: number): number;

    /**
     * Sets the color of a pixel in the imageData.
     *
     * @param x     The X coordinates of the pixel.
     * @param y     The Y coordinates of the pixel.
     * @param color The new color of the pixel.
     */
    setPixel(this: ImageData, x: number, y: number, color: number): ImageData;

    /**
     * Applies a `PixelFunction` on all the pixels of the imageData.
     *
     * @param mapper The `PixelFunction` to apply on all the pixels.
     */
    mapPixels(this: ImageData, mapper: PixelFunction): ImageData;

    // TODO: paste
    // TODO: export

    /**
     * Pastes the content of another imageData into this imageData.
     *
     * @param source    The source imageData, can't be null!
     * @param destX     The destination's top-left corner X coordinates to paste the image at. Defaults to 0.
     * @param destY     The destination's top-left corner Y coordinates to paste the image at. Defaults to 0.
     * @param srcX      The X coordinates of the region to paste from the source imageData. Defaults to 0.
     * @param srcY      The Y coordinates of the region to paste from the source imageData. Defaults to 0.
     * @param srcWidth  The width of the region to paste from the source imageData in pixels. Defaults to the source imageData's width.
     * @param srcHeight The height of the region to paste from the source imageData in pixels. Defaults to the source imageData's height.
     */
    paste(this: ImageData, source: ImageData, destX?: number, destY?: number, srcX?: number, srcY?: number, srcWidth?: number, srcHeight?: number): ImageData;

    /**
     * Creates a drawable Image from this ImageData.
     * The content of the created Image can be updated using {@code Image.refresh()}.
     *
     * @return The created drawable Image.
     */
    toImage(this: ImageData): Image;

    /**
     * Encodes the imageData into a PNG image, using the current active colorPalette.
     *
     * @return The encoded PNG binary data as a bytes array.
     */
    export(this: ImageData): string;
}