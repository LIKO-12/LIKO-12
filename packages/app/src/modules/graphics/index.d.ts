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
import { ImageData, LovePixelFunction } from "./image-data";
export default class Graphics extends MachineModule {
    protected activeColor: number;
    protected readonly effectsShader: import("love.graphics").Shader<{
        u_transparent: number[];
        u_remap: number[];
    }>;
    /**
     * Effective only on images, not on any shapes/geometry drawing operation.
     *
     * 1.0 for transparent, 0.0 for opaque.
     *
     * by default all colors are opaque except color 0.
     */
    protected readonly paletteTransparency: number[];
    protected readonly paletteRemap: number[];
    readonly mapImportedImageColors: LovePixelFunction;
    constructor(machine: Machine, options: {});
    activate(): void;
    deactivate(): void;
    private activateColor;
    createAPI(_machine: Machine): {
        /**
         * Create a new ImageData with specific dimensions, and zero-fill it.
         */
        newImageData: (width: number, height: number) => ImageData;
        /**
         * Create an ImageData from a PNG image.
         * @param data The binary representation of the PNG image to import.
         */
        importImageData: (data: string) => ImageData;
        /**
         * Remaps a color on all drawing operations.
         *
         * @param from The color to replace.
         * @param to The color which will replace `from`.
         */
        remapColor: (from: number, to: number) => void;
        /**
         * Make a specific color transparent (invisible) when drawing an image.
         *
         * @param color The target. Defaults to the active color.
         */
        makeColorTransparent: (color?: number) => void;
        /**
         * Make a specific color opaque (visible) when drawing an image.
         *
         * @param color @param color The target. Defaults to the active color.
         */
        makeColorOpaque: (color?: number) => void;
        /**
         * Get and/or set the active color.
         *
         * @param color The new color to set.
         * @returns The currently active / newly set color.
         */
        color: (color?: number) => number;
        /**
         * Clear the screen and fill it with a specific color.
         *
         * @param color The color to use. Defaults to the active color.
         */
        clear: (color?: number) => void;
        /**
         * Draw a point on the screen.
         *
         * @param color The color to use. Defaults to the active color.
         */
        point: (x: number, y: number, color?: number) => void;
        /**
         * Draw multiple points on the screen.
         *
         * @example points([16,16, 32,16, 16,32, 32,32], 7);
         *
         * @param coords The coordinates of the points, **must contain an even number of elements.**
         * @param color The color to use. Defaults to the active color.
         */
        points: (coords: number[], color?: number) => void;
        /**
         * Draw a line on the screen.
         *
         * @param color The color to use. Defaults to the active color.
         */
        line: (x1: number, y1: number, x2: number, y2: number, color?: number) => void;
        /**
         * Draw multiple lines on the screen.
         *
         * @example lines([16,16, 32,16, 16,32, 32,32], 7);
         *
         * @param coords The coordinates of the line vertices, **must contain an even number of elements.**
         * @param color The color to use. Defaults to the active color.
         */
        lines: (coords: number[], color?: number) => void;
        /**
         * Draw a triangle on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        triangle: (x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, filled?: boolean, color?: number) => void;
        /**
         * Draw a rectangle on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        rectangle: (x: number, y: number, width: number, height: number, filled?: boolean, color?: number) => void;
        /**
         * Draw a polygon on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        polygon: (vertices: number[], filled?: boolean, color?: number) => void;
        /**
         * Draw a circle on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        circle: (centerX: number, centerY: number, radius: number, filled?: boolean, color?: number) => void;
        /**
         * Draw an ellipse on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        ellipse: (centerX: number, centerY: number, radiusX: number, radiusY: number, filled?: boolean, color?: number) => void;
    };
    /**
     * For drawing shapes on the screen.
     */
    createShapesAPI(): {
        /**
         * Get and/or set the active color.
         *
         * @param color The new color to set.
         * @returns The currently active / newly set color.
         */
        color: (color?: number) => number;
        /**
         * Clear the screen and fill it with a specific color.
         *
         * @param color The color to use. Defaults to the active color.
         */
        clear: (color?: number) => void;
        /**
         * Draw a point on the screen.
         *
         * @param color The color to use. Defaults to the active color.
         */
        point: (x: number, y: number, color?: number) => void;
        /**
         * Draw multiple points on the screen.
         *
         * @example points([16,16, 32,16, 16,32, 32,32], 7);
         *
         * @param coords The coordinates of the points, **must contain an even number of elements.**
         * @param color The color to use. Defaults to the active color.
         */
        points: (coords: number[], color?: number) => void;
        /**
         * Draw a line on the screen.
         *
         * @param color The color to use. Defaults to the active color.
         */
        line: (x1: number, y1: number, x2: number, y2: number, color?: number) => void;
        /**
         * Draw multiple lines on the screen.
         *
         * @example lines([16,16, 32,16, 16,32, 32,32], 7);
         *
         * @param coords The coordinates of the line vertices, **must contain an even number of elements.**
         * @param color The color to use. Defaults to the active color.
         */
        lines: (coords: number[], color?: number) => void;
        /**
         * Draw a triangle on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        triangle: (x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, filled?: boolean, color?: number) => void;
        /**
         * Draw a rectangle on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        rectangle: (x: number, y: number, width: number, height: number, filled?: boolean, color?: number) => void;
        /**
         * Draw a polygon on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        polygon: (vertices: number[], filled?: boolean, color?: number) => void;
        /**
         * Draw a circle on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        circle: (centerX: number, centerY: number, radius: number, filled?: boolean, color?: number) => void;
        /**
         * Draw an ellipse on the screen.
         *
         * @param filled Whether to fill or only outline. Defaults to false (outline).
         * @param color The color to use. Defaults to the active color.
         */
        ellipse: (centerX: number, centerY: number, radiusX: number, radiusY: number, filled?: boolean, color?: number) => void;
    };
    /**
     * For applying some graphics effects.
     */
    createEffectsAPI(): {
        /**
         * Remaps a color on all drawing operations.
         *
         * @param from The color to replace.
         * @param to The color which will replace `from`.
         */
        remapColor: (from: number, to: number) => void;
        /**
         * Make a specific color transparent (invisible) when drawing an image.
         *
         * @param color The target. Defaults to the active color.
         */
        makeColorTransparent: (color?: number) => void;
        /**
         * Make a specific color opaque (visible) when drawing an image.
         *
         * @param color @param color The target. Defaults to the active color.
         */
        makeColorOpaque: (color?: number) => void;
    };
    createImagesAPI(): {
        /**
         * Create a new ImageData with specific dimensions, and zero-fill it.
         */
        newImageData: (width: number, height: number) => ImageData;
        /**
         * Create an ImageData from a PNG image.
         * @param data The binary representation of the PNG image to import.
         */
        importImageData: (data: string) => ImageData;
    };
    private uploadPaletteTransparency;
    private uploadPaletteRemap;
    private loadEffectsShader;
}
//# sourceMappingURL=index.d.ts.map