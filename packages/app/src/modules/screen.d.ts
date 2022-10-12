/// <reference types="@typescript-to-lua/language-extensions" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/alignmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/arctype" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/areaspreaddistribution" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/blendalphamode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/blendmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/comparemode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/cullmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/drawmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/filtermode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/graphicsfeature" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/graphicslimit" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/indexdatatype" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/linejoin" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/linestyle" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/matrixlayout" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/meshdrawmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/mipmapmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/particleinsertmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/shadervariabletype" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/spritebatchusage" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/stacktype" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/stencilaction" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/texturetype" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/vertexattributestep" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/vertexwinding" />
/// <reference types="love-typescript-definitions/typings/love.graphics/enums/wrapmode" />
/// <reference types="love-typescript-definitions/typings/love.graphics/functions" />
/// <reference types="love-typescript-definitions/typings/love.graphics/structs/displayflags" />
/// <reference types="love-typescript-definitions/typings/love.graphics/structs/imageinformation" />
/// <reference types="love-typescript-definitions/typings/love.graphics/structs/imagesettings" />
/// <reference types="love-typescript-definitions/typings/love.graphics/structs/meshvertexdatatype" />
/// <reference types="love-typescript-definitions/typings/love.graphics/structs/vertexattribute" />
/// <reference types="love-typescript-definitions/typings/love.graphics/structs/vertexinformation" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/canvas" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/drawable" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/font" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/image" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/mesh" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/particlesystem" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/quad" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/shader" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/spritebatch" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/text" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/texture" />
/// <reference types="love-typescript-definitions/typings/love.graphics/types/video" />
/** @noSelfInFile */
import Machine from "core/machine";
import MachineModule from "core/machine-module";
import { Canvas } from "love.graphics";
export interface ScreenOptions {
    width: number;
    height: number;
    /**
     * Path to an image containing the palette colors.
     */
    palette: string;
    /**
     * @default 0
     */
    x?: number;
    /**
     * @default 0
     */
    y?: number;
    /**
     * @default 1
     */
    scaleX?: number;
    /**
     * @default 1
     */
    scaleY?: number;
    /**
     * @default true
     */
    fitToWindow?: boolean;
    /**
     * @default false
     */
    pixelPerfect?: boolean;
}
export default class Screen extends MachineModule {
    private machine;
    protected readonly framebuffer: Canvas;
    protected readonly palette: [r: number, g: number, b: number, a: number][];
    protected readonly displayShader: import("love.graphics").Shader<{
        u_palette: [
            r: number,
            g: number,
            b: number,
            a: number
        ][];
    }>;
    x: number;
    y: number;
    scaleX: number;
    scaleY: number;
    shouldFitToWindow: boolean;
    pixelPerfect: boolean;
    private resumeWhenFlipped;
    constructor(machine: Machine, options: ScreenOptions);
    activate(): void;
    deactivate(): void;
    render(): void;
    getColorsCount(): number;
    getColor(color: number): LuaMultiReturn<[r: number, g: number, b: number, a: number]>;
    findColor(r: number, g: number, b: number): number;
    createAPI(_machine: Machine): {
        /**
         * Get the width of the screen in pixels.
         */
        getWidth: () => number;
        /**
         * Get the height of the screen in pixels.
         */
        getHeight: () => number;
        /**
         * Wait until the screen is applied and shown to the user.
         *
         * Helpful when doing some loading operations.
         */
        flip: () => void;
        /**
         * Set the RGB values of a palette color.
         *
         * @param color The palette's color to set.
         * @param r     The red channel value [0-255]
         * @param g     The green channel value [0-255].
         * @param b     The blue channel value [0-255].
         */
        setPaletteColor: (color: number, r: number, g: number, b: number) => void;
    };
    private fitToWindow;
    private loadPalette;
    private loadDisplayShader;
    private uploadPalette;
}
//# sourceMappingURL=screen.d.ts.map