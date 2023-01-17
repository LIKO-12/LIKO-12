import { Machine } from "core/machine";
import { MachineModule } from "core/machine-module";
import { proxy, unproxy } from "core/object-proxy";
import { clamp, validateParameters } from "core/utilities";

import Screen from "../screen";
import { ImageData, LovePixelFunction } from "./image-data";

// TODO: palette soft-limit
// TODO: automatic offset detection
// TODO: possibly break each api into a file

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

    createAPI(_machine: Machine): StandardModules.GraphicsAPI {
        return {
            ...this.createShapesAPI(),
            ...this.createEffectsAPI(),
            ...this.createImagesAPI(),
        }
    }

    /**
     * For drawing shapes on the screen.
     */
    createShapesAPI(): StandardModules.Graphics.ShapesAPI {
        return {
            color: (color = this.activeColor): number => {
                validateParameters();

                this.activeColor = clamp(color, 0, 255, true);
                return color;
            },

            clear: (color = this.activeColor): void => {
                validateParameters();

                color = this.paletteRemap[clamp(color, 0, 255)];
                love.graphics.clear(color / 255, 1, 1, 1);
            },

            point: (x: number, y: number, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.points(x, y);
            },

            points: (coords: number[], color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.points(coords);
            },

            line: (x1: number, y1: number, x2: number, y2: number, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.line(x1, y1, x2, y2);
            },

            lines: (coords: number[], color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.line(coords);
            },

            triangle: (x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.polygon(filled ? 'fill' : 'line', x1, y1, x2, y2, x3, y3);
            },

            rectangle: (x: number, y: number, width: number, height: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.rectangle(filled ? 'fill' : 'line', x, y, width, height);
            },

            polygon: (vertices: number[], filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.polygon(filled ? 'fill' : 'line', vertices);
            },

            circle: (centerX: number, centerY: number, radius: number, filled = false, color = this.activeColor): void => {
                validateParameters();

                this.activateColor(color);
                love.graphics.circle(filled ? 'fill' : 'line', centerX, centerY, radius);
            },

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
    createEffectsAPI(): StandardModules.Graphics.EffectsAPI {
        return {
            remapColor: (from: number, to: number): void => {
                validateParameters();

                this.paletteRemap[from] = to;
                this.uploadPaletteRemap();
            },

            makeColorTransparent: (color = this.activeColor): void => {
                validateParameters();

                this.paletteTransparency[color] = 1;
                this.uploadPaletteTransparency();
            },

            makeColorOpaque: (color = this.activeColor): void => {
                validateParameters();

                this.paletteTransparency[color] = 0;
                this.uploadPaletteTransparency();
            },
        };
    }

    createImagesAPI(): StandardModules.Graphics.ImagesAPI {
        return {
            newImageData: (width: number, height: number): ImageData => {
                validateParameters();

                width = Math.floor(Math.max(width, 0));
                height = Math.floor(Math.max(height, 0));

                return proxy(ImageData._newImageData(this, width, height));
            },

            importImageData: (data: string): ImageData => {
                validateParameters();
                return proxy(ImageData._importImageData(this, data));
            },
            
            isImageData: (value: unknown): value is ImageData => {
                return unproxy(value) instanceof ImageData;
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