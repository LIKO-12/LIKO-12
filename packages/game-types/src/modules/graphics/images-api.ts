/// <reference path="./image.ts" />
/// <reference path="./image-data.ts" />

export interface ImagesAPI {
    /**
     * Create a new ImageData with specific dimensions, and zero-fill it.
     */
    newImageData(this: void, width: number, height: number): ImageData;

    /**
     * Create an ImageData from a PNG image.
     * @param data The binary representation of the PNG image to import.
     */
    importImageData(this: void, data: string): ImageData;

    /**
     * Checks a value if it's an ImageData or not.
     * @param value The value to check.
     */
    isImageData(this: void, value: unknown): value is ImageData;
}