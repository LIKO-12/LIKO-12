import { validateParameters } from 'core/utilities';

import { Image as LoveImage, Quad } from 'love.graphics';
import { ImageData as LoveImageData } from 'love.image';

export class _Image implements Image {
    protected readonly image: LoveImage;
    protected readonly quad: Quad;

    constructor(protected readonly imageData: LoveImageData) {
        this.image = love.graphics.newImage(imageData);
        this.image.setFilter('nearest', 'nearest');
        this.image.setWrap('repeat', 'repeat');

        const [width, height] = this.image.getDimensions();
        this.quad = love.graphics.newQuad(0, 0, width, height, width, height);
    }

    getWidth(): number {
        return this.image.getWidth();
    }

    getHeight(): number {
        return this.image.getHeight();
    }

    draw(x = 0, y = 0, rotation = 0, scaleX = 1, scaleY = 1, srcX = 0, srcY = 0, srcWidth = this.getWidth(), srcHeight = this.getHeight()): Image {
        validateParameters();

        if (srcX !== 0 || srcY !== 0 || srcWidth !== this.getWidth() || srcHeight !== this.getHeight()) {
            this.quad.setViewport(srcX, srcY, srcWidth, srcHeight);
            love.graphics.draw(this.image, this.quad, x, y, rotation, scaleX, scaleY);
        } else {
            love.graphics.draw(this.image, x, y, rotation, scaleX, scaleY);
        }

        return this;
    }

    refresh(): Image {
        this.image.replacePixels(this.imageData, 0);
        return this;
    }
}