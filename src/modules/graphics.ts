import Machine from "core/machine";
import MachineModule from "core/machine-module";
import { proxy } from "core/object-proxy";
import { clamp, validateParameters } from "core/utilities";

import { ImageData as LoveImageData } from 'love.image';
import Screen from "./screen";

// TODO: palette soft-limit

type LovePixelFunction = (x: number, y: number, r: number, g: number, b: number, a: number) => LuaMultiReturn<[r: number, g: number, b: number, a: number]>;
type PixelFunction = (x: number, y: number, color: number) => number;

class ImageData {
    constructor(private graphics: Graphics, private imageData: LoveImageData) {
    }

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

    // TODO: paste
    // TODO: toImage
    // TODO: export

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

export default class Graphics extends MachineModule {
    protected activeColor = 0;

    protected readonly effectsShader = this.loadEffectsShader();

    /**
     * Effective only on images, not on any shapes/geometry drawing operation.
     * 
     * 1.0 for transparent, 0.0 for opaque.
     * 
     * by default all colors are opaque except color 0.
     */
    protected readonly paletteTransparency: number[] = [];

    protected readonly paletteRemap: number[] = [];

    public readonly mapImportedImageColors: LovePixelFunction;

    constructor(machine: Machine, options: {}) {
        super(machine, options);

        // Initialize the palettes effects arrays.
        for (let i = 0; i < 256; i++) {
            this.paletteRemap[i] = i;
            this.paletteTransparency[i] = 0;
        };
        this.paletteTransparency[0] = 1;
        this.uploadPaletteTransparency();
        this.uploadPaletteRemap();

        love.graphics.setLineWidth(1);
        love.graphics.setLineJoin('miter');
        love.graphics.setLineStyle('rough');

        machine.events.on('resumed', () => this.activate());
        machine.events.on('suspended', () => this.deactivate());

        const screen = machine.resolveModule<Screen>('screen')!;

        this.mapImportedImageColors = (_x, _y, r, g, b, _a) => {
            const color = screen.findColor(r, g, b);
            return $multi(color / 255, 0, 0, 1);
        };
    }

    activate() {
        love.graphics.setShader(this.effectsShader);
    }

    deactivate() {
        love.graphics.setShader();
    }

    private activateColor(color = this.activeColor) {
        // TODO: check the range of the color.
        love.graphics.setColor(color / 255.0, 1, 1, 1);
    }

    createAPI(_machine: Machine) {
        return {
            ...this.createShapesAPI(),
            ...this.createEffectsAPI(),
            ...this.createImagesAPI(),
        }
    }

    /**
     * For drawing shapes on the screen.
     */
    createShapesAPI() {
        return {
            /**
             * Get and/or set the active color.
             * 
             * @param color The new color to set.
             * @returns The currently active / newly set color.
             */
            color: (color = this.activeColor): number => {
                validateParameters();

                this.activeColor = clamp(color, 0, 255, true);
                return color;
            },

            /**
             * Clear the screen and fill it with a specific color.
             * 
             * @param color The color to use. Defaults to the active color.
             */
            clear: (color = this.activeColor): void => {
                validateParameters();

                color = this.paletteRemap[clamp(color, 0, 255)];
                love.graphics.clear(color / 255, 1, 1, 1);
            },

            /**
             * Draw a point on the screen.
             * 
             * @param color The color to use. Defaults to the active color.
             */
            point: (x: number, y: number, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.points(x, y);
            },

            /**
             * Draw multiple points on the screen.
             * 
             * @example points([16,16, 32,16, 16,32, 32,32], 7);
             * 
             * @param coords The coordinates of the points, **must contain an even number of elements.**
             * @param color The color to use. Defaults to the active color.
             */
            points: (coords: number[], color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.points(coords);
            },

            /**
             * Draw a line on the screen.
             * 
             * @param color The color to use. Defaults to the active color.
             */
            line: (x1: number, y1: number, x2: number, y2: number, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.line(x1, y1, x2, y2);
            },

            /**
             * Draw multiple lines on the screen.
             * 
             * @example lines([16,16, 32,16, 16,32, 32,32], 7);
             * 
             * @param coords The coordinates of the line vertices, **must contain an even number of elements.**
             * @param color The color to use. Defaults to the active color.
             */
            lines: (coords: number[], color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.line(coords);
            },

            /**
             * Draw a triangle on the screen.
             * 
             * @param filled Whether to fill or only outline. Defaults to false (outline).
             * @param color The color to use. Defaults to the active color.
             */
            triangle: (x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.polygon(filled ? 'fill' : 'line', x1, y1, x2, y2, x3, y3);
            },

            /**
             * Draw a rectangle on the screen.
             * 
             * @param filled Whether to fill or only outline. Defaults to false (outline).
             * @param color The color to use. Defaults to the active color.
             */
            rectangle: (x: number, y: number, width: number, height: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.rectangle(filled ? 'fill' : 'line', x, y, width, height);
            },

            /**
             * Draw a polygon on the screen.
             * 
             * @param filled Whether to fill or only outline. Defaults to false (outline).
             * @param color The color to use. Defaults to the active color.
             */
            polygon: (vertices: number[], filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.polygon(filled ? 'fill' : 'line', vertices);
            },

            /**
             * Draw a circle on the screen.
             * 
             * @param filled Whether to fill or only outline. Defaults to false (outline).
             * @param color The color to use. Defaults to the active color.
             */
            circle: (centerX: number, centerY: number, radius: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.circle(filled ? 'fill' : 'line', centerX, centerY, radius);
            },

            /**
             * Draw an ellipse on the screen.
             * 
             * @param filled Whether to fill or only outline. Defaults to false (outline).
             * @param color The color to use. Defaults to the active color.
             */
            ellipse: (centerX: number, centerY: number, radiusX: number, radiusY: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.ellipse(filled ? 'fill' : 'line', centerX, centerY, radiusX, radiusY);
            },
        };
    }

    /**
     * For applying some graphics effects.
     */
    createEffectsAPI() {
        return {
            // TODO: clipping (setClip).
            // TODO: patterns (setDrawingPattern).
            // TODO: transformations (setMatrix, getMatrix).

            /**
             * Remaps a color on all drawing operations.
             * 
             * @param from The color to replace.
             * @param to The color which will replace `from`.
             */
            remapColor: (from: number, to: number): void => {
                validateParameters();

                this.paletteRemap[from] = to;
                this.uploadPaletteRemap();
            },

            /**
             * Make a specific color transparent (invisible) when drawing an image.
             * 
             * @param color The target. Defaults to the active color.
             */
            makeColorTransparent: (color = this.activeColor): void => {
                validateParameters();

                this.paletteTransparency[color] = 1;
                this.uploadPaletteTransparency();
            },

            /**
             * Make a specific color opaque (visible) when drawing an image.
             * 
             * @param color @param color The target. Defaults to the active color.
             */
            makeColorOpaque: (color = this.activeColor): void => {
                validateParameters();

                this.paletteTransparency[color] = 1;
                this.uploadPaletteTransparency();
            },
        };
    }

    createImagesAPI() {
        return {
            /**
             * Create a new ImageData with specific dimensions, and zero-fill it.
             */
            newImageData: (width: number, height: number): ImageData => {
                validateParameters();

                width = Math.floor(Math.max(width, 0));
                height = Math.floor(Math.max(height, 0));

                return proxy(ImageData._newImageData(this, width, height));
            },

            /**
             * Create an ImageData from a PNG image.
             * @param data The binary representation of the PNG image to import.
             */
            importImageData: (data: string): ImageData => {
                validateParameters();
                return proxy(ImageData._importImageData(this, data));
            },
        };
    }

    private uploadPaletteTransparency() {
        this.effectsShader.send('u_transparent', ...this.paletteTransparency);
    }

    private uploadPaletteRemap() {
        this.effectsShader.send('u_remap', ...this.paletteRemap);
    }

    private loadEffectsShader() {
        try {
            const shader = love.graphics.newShader<{
                u_transparent: number[],
                u_remap: number[],
            }>('res/shaders/effects.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] effects shader:', warnings);

            return shader;
        } catch (error: unknown) {
            print(error);
            print('[WARNING] failed to load standard effects shader, falling back to the compatibility one.');

            const shader = love.graphics.newShader<{
                u_transparent: number[],
                u_remap: number[],
            }>('res/shaders/effects-compat.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] effects-compat shader:', warnings);

            return shader;
        }
    }
}