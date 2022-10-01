import loveEvents from "core/love-events";
import Machine from "core/machine";
import MachineModule from "core/machine-module";
import { assertOption } from "core/utilities";

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

    constructor(machine: Machine, options: ScreenOptions) {
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
    }

    createAPI(_machine: Machine) {
        return {
            getWidth: () => this.framebuffer.getWidth(),
            getHeight: () => this.framebuffer.getHeight(),
            getDimensions: () => this.framebuffer.getDimensions(),
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
    }

    private loadDisplayShader() {
        try {
            const shader = love.graphics.newShader<{
                u_palette: [r: number, g: number, b: number, a: number][]
            }>('res/shaders/display.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] display shader:', warnings);

            return shader;
        } catch (error: unknown) {
            print(error);
            print('[WARNING] failed to load standard display shader, falling back to compatibility one.');

            const shader = love.graphics.newShader<{
                u_palette: [r: number, g: number, b: number, a: number][]
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