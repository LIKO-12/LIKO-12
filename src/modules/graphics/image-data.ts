import { clamp, validateParameters } from 'core/utilities';
import { ImageData as LoveImageData } from 'love.image';

import Graphics from ".";
import { Image } from './image';

export type LovePixelFunction = (x: number, y: number, r: number, g: number, b: number, a: number) => LuaMultiReturn<[r: number, g: number, b: number, a: number]>;
export type PixelFunction = (x: number, y: number, color: number) => number;

// TODO: palette soft-limit

export class ImageData {
    constructor(private graphics: Graphics, private imageData: LoveImageData) {
    }

    /**
     * Gets the width of the imageData.
     *
     * @return The width of the image in pixels.
     */
    getWidth(): number {
        return this.imageData.getWidth();
    }

    /**
     * Gets the height of the imageData.
     *
     * @return The height of the image in pixels.
     */
    getHeight(): number {
        return this.imageData.getHeight();
    }

    /**
     * Gets the color of a pixel in the imageData.
     *
     * @param x The X coordinates of the pixel.
     * @param y The Y coordinates of the pixel.
     * @return The color of the pixel.
     */
    getPixel(x: number, y: number): number {
        validateParameters();

        x = clamp(x, 0, this.getWidth() - 1, true);
        y = clamp(y, 0, this.getHeight() - 1, true);

        const [r] = this.imageData.getPixel(x, y);
        return r * 255;
    }

    /**
     * Sets the color of a pixel in the imageData.
     *
     * @param x     The X coordinates of the pixel.
     * @param y     The Y coordinates of the pixel.
     * @param color The new color of the pixel.
     */
    setPixel(x: number, y: number, color: number): ImageData {
        validateParameters();

        x = clamp(x, 0, this.getWidth() - 1, true);
        y = clamp(y, 0, this.getHeight() - 1, true);
        color = clamp(color, 0, 255, true);

        this.imageData.setPixel(x, y, color / 255, 0, 0, 1);

        return this;
    }

    /**
     * Applies a `PixelFunction` on all the pixels of the imageData.
     *
     * @param mapper The `PixelFunction` to apply on all the pixels.
     */
    mapPixels(mapper: PixelFunction): ImageData {
        validateParameters();

        this.imageData.mapPixel((x: number, y: number, r: number) => {
            const c = mapper(x, y, Math.floor(r * 255));
            if (typeof c !== 'number') return error(`bad return value by the pixel function (number expected, got ${type(r)}`);
            return $multi(clamp(c, 0, 255, true) / 255, 0, 0, 1);
        });

        return this;
    }

    // TODO: paste
    // TODO: toImage
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
    paste(source: ImageData, destX?: number, destY?: number, srcX?: number, srcY?: number, srcWidth?: number, srcHeight?: number): void {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    /**
     * Creates a drawable Image from this ImageData.
     * The content of the created Image can be updated using {@code Image.refresh()}.
     *
     * @return The created drawable Image.
     */
    toImage(): Image {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    /**
     * Encodes the imageData into a PNG image, using the current active colorPalette.
     *
     * @return The encoded PNG binary data as a bytes array.
     */
    export(): string {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    private static _initializeEmptyImage: LovePixelFunction = () => {
        // Important: the blue channel must be 0.0 for the effects shader to work.
        return $multi(0, 0, 0, 1); // r,g,b,a
    };

    static _newImageData(graphics: Graphics, width: number, height: number): ImageData {
        const imageData = love.image.newImageData(width, height);
        imageData.mapPixel(ImageData._initializeEmptyImage);
        return new ImageData(graphics, imageData);
    }

    static _importImageData(graphics: Graphics, data: string): ImageData {
        try {
            const fileData = love.filesystem.newFileData(data, 'image.png');
            const imageData = love.image.newImageData(fileData);
            imageData.mapPixel(graphics.mapImportedImageColors);
            return new ImageData(graphics, imageData);
        } catch (err: any) {
            error(err, 3);
        }
    }
}