import loveEvents from "core/love-events";
import Machine from "core/machine";
import MachineModule from "core/machine-module";
import { assertOption, clamp, validateParameters } from "core/utilities";

import { Canvas } from "love.graphics";

export interface ScreenOptions {
    width: number,
    height: number,

    /**
     * Path to an image containing the palette colors.
     */
    palette: string,

    /**
     * @default 0
     */
    x?: number,
    /**
     * @default 0
     */
    y?: number,
    /**
     * @default 1
     */
    scaleX?: number,
    /**
     * @default 1
     */
    scaleY?: number,

    /**
     * @default true
     */
    fitToWindow?: boolean,
    /**
     * @default false
     */
    pixelPerfect?: boolean,
}

export default class Screen extends MachineModule {
    protected readonly framebuffer: Canvas;
    protected readonly palette: [r: number, g: number, b: number, a: number][] = [];

    protected readonly displayShader = this.loadDisplayShader();

    x: number;
    y: number;
    scaleX: number;
    scaleY: number;

    shouldFitToWindow: boolean;
    pixelPerfect: boolean;

    private resumeWhenFlipped = false;

    constructor(private machine: Machine, options: ScreenOptions) {
        super(machine, options);

        this.shouldFitToWindow = assertOption(options.fitToWindow ?? true, 'fitToWindow', 'boolean');
        this.pixelPerfect = assertOption(options.pixelPerfect ?? false, 'pixelPerfect', 'boolean');

        this.x = assertOption(options.x ?? 0, 'x', 'number');
        this.y = assertOption(options.y ?? 0, 'y', 'number');
        this.scaleX = assertOption(options.scaleX ?? 1, 'scaleX', 'number');
        this.scaleY = assertOption(options.scaleY ?? 1, 'scaleY', 'number');

        this.framebuffer = love.graphics.newCanvas(
            assertOption(options.width, 'width', 'number'),
            assertOption(options.height, 'height', 'number'),
            { dpiscale: 1 },
        );
        this.framebuffer.setFilter('nearest', 'nearest');

        this.fitToWindow();

        this.loadPalette(assertOption(options.palette, 'palette', 'string'));
        this.uploadPalette();

        machine.events.on('resumed', () => this.activate());
        machine.events.on('suspended', () => this.deactivate());

        loveEvents.on('draw', () => this.render());
        loveEvents.on('resize', () => this.fitToWindow());
    }

    activate() {
        love.graphics.setCanvas(this.framebuffer);
    }

    deactivate() {
        love.graphics.setCanvas();
    }

    render() {
        love.graphics.setShader(this.displayShader);

        const { framebuffer, x, y, scaleX, scaleY } = this;
        love.graphics.draw(framebuffer, x, y, undefined, scaleX, scaleY);

        love.graphics.setShader();

        if (this.resumeWhenFlipped) {
            this.resumeWhenFlipped = false;
            this.machine.resume();
        }
    }

    getColorsCount() {
        return this.palette.length;
    }

    getColor(color: number) {
        const rgba = this.palette[color] ?? [];
        return $multi(...rgba);
    }

    findColor(r: number, g: number, b: number): number {
        const color = this.palette.findIndex(([pr, pg, pb]) => pr === r && pg === g && pb === b);
        return color === -1 ? 0 : color;
    }

    createAPI(_machine: Machine) {
        return {
            /**
             * Get the width of the screen in pixels.
             */
            getWidth: (): number => this.framebuffer.getWidth(),
            /**
             * Get the height of the screen in pixels.
             */
            getHeight: (): number => this.framebuffer.getHeight(),

            /**
             * Wait until the screen is applied and shown to the user.
             * 
             * Helpful when doing some loading operations.
             */
            flip: (): void => {
                this.resumeWhenFlipped = true;
                coroutine.yield();
            },

            // TODO: initialize the screen module with no palette pre-loaded.

            // TODO: take screenshot imagedata

            /**
             * Set the RGB values of a palette color.
             * 
             * @param color The palette's color to set.
             * @param r     The red channel value [0-255]
             * @param g     The green channel value [0-255].
             * @param b     The blue channel value [0-255].
             */
            setPaletteColor: (color: number, r: number, g: number, b: number): void => {
                validateParameters();

                color = clamp(color, 0, 255, true), r = clamp(r, 0, 255), g = clamp(g, 0, 255), b = clamp(b, 0, 255);

                this.palette[color] = [r / 255, g / 255, b / 255, 1];
                this.uploadPalette();
            },
        };
    }

    private fitToWindow() {
        if (!this.shouldFitToWindow) return;

        const [windowWidth, windowHeight] = love.graphics.getDimensions();
        const screenWidth = this.framebuffer.getWidth(), screenHeight = this.framebuffer.getHeight();

        const windowAspectRatio = windowWidth / windowHeight;
        const screenAspectRatio = screenWidth / screenHeight;

        let scale = windowAspectRatio < screenAspectRatio ? windowWidth / screenWidth : windowHeight / screenHeight;
        if (this.pixelPerfect) scale = Math.floor(scale);

        this.scaleX = scale;
        this.scaleY = scale;

        const renderedWidth = screenWidth * scale, renderedHeight = screenHeight * scale;

        this.x = windowWidth / 2 - renderedWidth / 2;
        this.y = windowHeight / 2 - renderedHeight / 2;

        if (love.window.getDisplayOrientation().startsWith('portrait')) this.x = 0;
    }

    private loadPalette(path: string) {
        if (!love.filesystem.getInfo(path, 'file')) throw new Error('options.palette points to a non-existing file');
        const imageData = love.image.newImageData(path);

        imageData.mapPixel((_x: number, _y: number, r: number, g: number, b: number, a: number) => {
            this.palette.push([r, g, b, a]);
            return $multi(r, g, b, a);
        });

        // TODO: no longer overfill the palette
        for (let i = this.palette.length; i < 256; i++)
            this.palette.push([1, 1, 1, 1]);
    }

    private loadDisplayShader() {
        try {
            const shader = love.graphics.newShader<{
                u_palette: [r: number, g: number, b: number, a: number][],
            }>('res/shaders/display.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] display shader:', warnings);

            return shader;
        } catch (error: unknown) {
            print(error);
            print('[WARNING] failed to load standard display shader, falling back to the compatibility one.');

            const shader = love.graphics.newShader<{
                u_palette: [r: number, g: number, b: number, a: number][],
            }>('res/shaders/display-compat.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] display-compat shader:', warnings);

            return shader;
        }
    }

    private uploadPalette() {
        this.displayShader.send('u_palette', ...this.palette);
    }
}