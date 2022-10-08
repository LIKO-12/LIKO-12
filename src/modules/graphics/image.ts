import { validateParameters } from 'core/utilities';

import { Image as LoveImage, Quad } from 'love.graphics';
import { ImageData as LoveImageData } from 'love.image';

export class Image {
    protected readonly image: LoveImage;
    protected readonly quad: Quad;

    constructor(protected readonly imageData: LoveImageData) {
        this.image = love.graphics.newImage(imageData);
        this.image.setFilter('nearest', 'nearest');
        this.image.setWrap('repeat', 'repeat');

        const [width, height] = this.image.getDimensions();
        this.quad = love.graphics.newQuad(0, 0, width, height, width, height);
    }

    /**
     * Gets the width of the image.
     *
     * @return The width of the image in pixels.
     */
    getWidth(): number {
        return this.image.getWidth();
    }

    /**
     * Gets the height of the image.
     *
     * @return The height of the image in pixels.
     */
    getHeight(): number {
        return this.image.getHeight();
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
    draw(x?: number, y?: number, rotation?: number, scaleX?: number, scaleY?: number, srcX?: number, srcY?: number, srcWidth?: number, srcHeight?: number): Image {
        validateParameters();

        if (srcX !== undefined || srcY !== undefined || srcWidth !== undefined || srcHeight !== undefined) {
            this.quad.setViewport(srcX ?? 0, srcY ?? 0, srcWidth ?? this.image.getWidth(), srcHeight ?? this.image.getHeight());
            love.graphics.draw(this.image, this.quad, x, y, rotation, scaleX, scaleY);
        } else {
            love.graphics.draw(this.image, this.quad, x, y, rotation, scaleX, scaleY);
        }

        return this;
    }

    /**
     * Updates the image's content from the ImageData used to create the image.
     */
    refresh(): Image {
        this.image.replacePixels(this.imageData, 0);
        return this;
    }
}