import Machine from "core/machine";
import MachineModule from "core/machine-module";

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
    protected readonly paletteTransparency: number[] = [1];

    protected readonly paletteRemap: number[] = [];


    constructor(machine: Machine, options: {}) {
        super(machine, options);

        // Initialize the palette remapping array.
        for (let i = 0; i < 256; i++) this.paletteRemap[i] = i;
        this.uploadPaletteTransparency();
        this.uploadPaletteRemap();

        love.graphics.setLineWidth(1);
        love.graphics.setLineJoin('miter');
        love.graphics.setLineStyle('rough');

        machine.events.on('resumed', () => this.activate());
        machine.events.on('suspended', () => this.deactivate());
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
                // FIXME: strong validate the parameters.
                this.activeColor = color ?? this.activeColor;
                return this.activeColor;
            },

            /**
             * Clear the screen and fill it with a specific color.
             * 
             * @param color The color to use. Defaults to the active color.
             */
            clear: (color = this.activeColor): void => {
                // FIXME: strong validate the parameters.
                love.graphics.clear((color ?? this.activeColor) / 255.0, 1, 1, 1);
            },

            /**
             * Draw a point on the screen.
             * 
             * @param color The color to use. Defaults to the active color.
             */
            point: (x: number, y: number, color = this.activeColor): void => {
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
                this.activateColor(color);
                love.graphics.points(coords);
            },

            /**
             * Draw a line on the screen.
             * 
             * @param color The color to use. Defaults to the active color.
             */
            line: (x1: number, y1: number, x2: number, y2: number, color = this.activeColor): void => {
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
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
                // FIXME: strong validate the parameters.
                this.paletteRemap[from] = to;
                this.uploadPaletteRemap();
            },

            /**
             * Make a specific color transparent (invisible) when drawing an image.
             * 
             * @param color The target. Defaults to the active color.
             */
            makeColorTransparent: (color = this.activeColor): void => {
                // FIXME: strong validate the parameters.
                this.paletteTransparency[color] = 1;
                this.uploadPaletteTransparency();
            },

            /**
             * Make a specific color opaque (visible) when drawing an image.
             * 
             * @param color @param color The target. Defaults to the active color.
             */
            makeColorOpaque: (color = this.activeColor): void => {
                // FIXME: strong validate the parameters.
                this.paletteTransparency[color] = 1;
                this.uploadPaletteTransparency();
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