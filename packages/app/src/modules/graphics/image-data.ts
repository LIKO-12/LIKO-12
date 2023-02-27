import { proxy } from 'core/object-proxy';
import { clamp, validateParameters } from 'core/utilities';
import { ImageData as LoveImageData } from 'love.image';

import Graphics from ".";
import { _Image } from './image';

export type LovePixelFunction = (x: number, y: number, r: number, g: number, b: number, a: number) => LuaMultiReturn<[r: number, g: number, b: number, a: number]>;

// TODO: palette soft-limit

export class _ImageData implements ImageData {
    constructor(
        protected readonly graphics: Graphics,
        protected readonly imageData: LoveImageData,
    ) { }

    getWidth(): number {
        return this.imageData.getWidth();
    }

    getHeight(): number {
        return this.imageData.getHeight();
    }

    getPixel(x: number, y: number): number {
        validateParameters();

        x = clamp(x, 0, this.getWidth() - 1, true);
        y = clamp(y, 0, this.getHeight() - 1, true);

        const [r] = this.imageData.getPixel(x, y);
        return r * 255;
    }

    setPixel(x: number, y: number, color: number): ImageData {
        validateParameters();

        x = clamp(x, 0, this.getWidth() - 1, true);
        y = clamp(y, 0, this.getHeight() - 1, true);
        color = clamp(color, 0, 255, true);

        this.imageData.setPixel(x, y, color / 255, 0, 0, 1);

        return this;
    }

    mapPixels(mapper: PixelFunction): ImageData {
        validateParameters();

        this.imageData.mapPixel((x: number, y: number, r: number) => {
            const c = mapper(x, y, Math.floor(r * 255));
            if (typeof c !== 'number') return error(`bad return value by the pixel function (number expected, got ${type(r)}`);
            return $multi(clamp(c, 0, 255, true) / 255, 0, 0, 1);
        });

        return this;
    }

    paste(source: ImageData, destX?: number, destY?: number, srcX?: number, srcY?: number, srcWidth?: number, srcHeight?: number): ImageData {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    toImage(): Image {
        const image = new _Image(this.imageData);
        return proxy(image);
    }

    export(): string {
        throw new Error('Method not implemented.'); // FIXME: Unimplemented method.
    }

    protected static _initializeEmptyImage: LovePixelFunction = () => {
        // Important: the blue channel must be 0.0 for the effects shader to work.
        return $multi(0, 0, 0, 1); // r,g,b,a
    };

    static _newImageData(graphics: Graphics, width: number, height: number): ImageData {
        const imageData = love.image.newImageData(width, height);
        imageData.mapPixel(_ImageData._initializeEmptyImage);
        return new _ImageData(graphics, imageData);
    }

    static _importImageData(graphics: Graphics, data: string): ImageData {
        try {
            const fileData = love.filesystem.newFileData(data, 'image.png');
            const imageData = love.image.newImageData(fileData);
            imageData.mapPixel(graphics.mapImportedImageColors);
            return new _ImageData(graphics, imageData);
        } catch (err: any) {
            error(err, 3);
        }
    }
}