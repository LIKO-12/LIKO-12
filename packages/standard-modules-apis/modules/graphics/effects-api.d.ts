declare namespace StandardModules {
    export namespace Graphics {
        /**
         * For applying some graphics effects.
         */
        export interface EffectsAPI {
            // TODO: clipping (setClip).
            // TODO: patterns (setDrawingPattern).
            // TODO: transformations (setMatrix, getMatrix).

            /**
             * Remaps a color on all drawing operations.
             * 
             * @param from The color to replace.
             * @param to The color which will replace `from`.
             */
            remapColor(this: void, from: number, to: number): void;

            /**
             * Make a specific color transparent (invisible) when drawing an image.
             * 
             * @param color The target. Defaults to the active color.
             */
            makeColorTransparent(this: void, color?: number): void;

            /**
             * Make a specific color opaque (visible) when drawing an image.
             * 
             * @param color @param color The target. Defaults to the active color.
             */
            makeColorOpaque(this: void, color?: number): void;
        }
    }
}