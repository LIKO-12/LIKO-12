import { Image as LoveImage } from 'love.graphics';

interface Test {
    
}

export class Image {
    constructor(image: LoveImage) {
    }

    /**
     * Gets the width of the image.
     *
     * @return The width of the image in pixels.
     */
    getWidth(): number {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    /**
     * Gets the height of the image.
     *
     * @return The height of the image in pixels.
     */
    getHeight(): number {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    /**
     * Draw the image on the screen.
     * 
     * @param x         The X coordinates of the top-left image's corner.
     * @param y         The Y coordinates of the top-left image's corner.
     * @param rotation  The rotation of the image in radians. Defaults to 0.
     * @param scaleX    The scale of the image on the X-axis. Defaults to 1.
     * @param scaleY    The scale of the image on the Y-axis. Defaults to 1.
     * @param srcX      The X coordinates of the region to draw from the image. Defaults to 0.
     * @param srcY      The Y coordinates of the region to draw from the image. Defaults to 0.
     * @param srcWidth  The width of the region to draw from the image in pixels. Defaults to the image's width.
     * @param srcHeight The height of the region to draw from the image in pixels. Defaults to the image's height.
     */
    draw(x?: number, y?: number, rotation?: number, scaleX?: number, scaleY?: number, srcX?: number, srcY?: number, srcWidth?: number, srcHeight?: number): void {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    /**
     * Updates the image's content from the ImageData used to create the image.
     */
    refresh(): void {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }
}