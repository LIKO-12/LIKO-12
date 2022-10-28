/// <reference path='./image-data.d.ts' />

declare namespace StandardModules {
    export namespace Graphics {
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
        }
    }
}