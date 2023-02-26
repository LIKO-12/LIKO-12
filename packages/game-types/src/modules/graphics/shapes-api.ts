/**
 * For drawing shapes on the screen.
 */
export interface ShapesAPI {
    /**
     * Get and/or set the active color.
     * 
     * @param color The new color to set.
     * @returns The currently active / newly set color.
     */
    color(this: void, color?: number): number;

    /**
     * Clear the screen and fill it with a specific color.
     * 
     * @param color The color to use. Defaults to the active color.
     */
    clear(this: void, color?: number): void;

    /**
     * Draw a point on the screen.
     * 
     * @param color The color to use. Defaults to the active color.
     */
    point(this: void, x: number, y: number, color?: number): void;

    /**
     * Draw multiple points on the screen.
     * 
     * @example points([16,16, 32,16, 16,32, 32,32], 7);
     * 
     * @param coords The coordinates of the points, **must contain an even number of elements.**
     * @param color The color to use. Defaults to the active color.
     */
    points(this: void, coords: number[], color?: number): void;

    /**
     * Draw a line on the screen.
     * 
     * @param color The color to use. Defaults to the active color.
     */
    line(this: void, x1: number, y1: number, x2: number, y2: number, color?: number): void;

    /**
     * Draw multiple lines on the screen.
     * 
     * @example lines([16,16, 32,16, 16,32, 32,32], 7);
     * 
     * @param coords The coordinates of the line vertices, **must contain an even number of elements.**
     * @param color The color to use. Defaults to the active color.
     */
    lines(this: void, coords: number[], color?: number): void;

    /**
     * Draw a triangle on the screen.
     * 
     * @param filled Whether to fill or only outline. Defaults to false (outline).
     * @param color The color to use. Defaults to the active color.
     */
    triangle(this: void, x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, filled?: boolean, color?: number): void;

    /**
     * Draw a rectangle on the screen.
     * 
     * @param filled Whether to fill or only outline. Defaults to false (outline).
     * @param color The color to use. Defaults to the active color.
     */
    rectangle(this: void, x: number, y: number, width: number, height: number, filled?: boolean, color?: number): void;
    /**
     * Draw a polygon on the screen.
     * 
     * @param filled Whether to fill or only outline. Defaults to false (outline).
     * @param color The color to use. Defaults to the active color.
     */
    polygon(this: void, vertices: number[], filled?: boolean, color?: number): void;

    /**
     * Draw a circle on the screen.
     * 
     * @param filled Whether to fill or only outline. Defaults to false (outline).
     * @param color The color to use. Defaults to the active color.
     */
    circle(this: void, centerX: number, centerY: number, radius: number, filled?: boolean, color?: number): void;

    /**
     * Draw an ellipse on the screen.
     * 
     * @param filled Whether to fill or only outline. Defaults to false (outline).
     * @param color The color to use. Defaults to the active color.
     */
    ellipse(this: void, centerX: number, centerY: number, radiusX: number, radiusY: number, filled?: boolean, color?: number): void;
}