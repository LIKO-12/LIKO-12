import loveEvents from "core/love-events";
import Machine from "core/machine";
import MachineModule from "core/machine-module";
import { assertOption } from "core/utilities";

import { Canvas } from "love.graphics";

export interface ScreenOptions {
    width: number,
    height: number,

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

        this.fitToWindow();
        
        this.framebuffer = love.graphics.newCanvas(
            assertOption(options.width, 'width', 'number'),
            assertOption(options.height, 'height', 'number'),
            { dpiscale: 1 },
        );

        this.framebuffer.setFilter('nearest', 'nearest');

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
        const { framebuffer, x, y, scaleX, scaleY } = this;
        love.graphics.draw(framebuffer, x, y, undefined, scaleX, scaleY);
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

    createAPI(_machine: Machine) {
        return {
            getWidth: () => this.framebuffer.getWidth(),
            getHeight: () => this.framebuffer.getHeight(),
            getDimensions: () => this.framebuffer.getDimensions(),
        };
    }
}