declare namespace StandardModules {
    export interface ScreenAPI {
        /**
         * Get the width of the screen in pixels.
         */
        getWidth(this: void): number;

        /**
         * Get the height of the screen in pixels.
         */
        getHeight(this: void): number;

        /**
         * Wait until the screen is applied and shown to the user.
         * 
         * Helpful when doing some loading operations.
         */
        flip(this: void): void;

        // TODO: take screenshot imagedata
        // TODO: add a method to query about the number of supported palette colors

        /**
         * Set the RGB values of a palette color.
         * 
         * @param color The palette's color to set.
         * @param r     The red channel value [0-255]
         * @param g     The green channel value [0-255].
         * @param b     The blue channel value [0-255].
         */
        setPaletteColor(this: void, color: number, r: number, g: number, b: number): void;
    }
}