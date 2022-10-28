/// <reference path="../constants/keys.d.ts" />
/// <reference path="../constants/scancode.d.ts" />

declare module "@liko-12/standard-modules-types" {
    export interface KeyboardAPI {
        /**
                     * Enable or disable text input events.
                     * It is enabled by default on Windows, Mac, and Linux, and disabled by default on iOS and Android.
                     * 
                     * It would also show the on-screen keyboard for touch devices.
                     */
        setTextInput(enable: boolean): void;

        /**
         * Get whether text input events are enabled.
         */
        hasTextInput(): boolean;

        /**
         * Get the hardware scancode corresponding to the given key.
         * @returns `"unknown"` if the given key has no known physical representation on the current system.
         */
        getScancodeFromKey(key: KeyConstant): Scancode;
        /**
         * Get the key corresponding to the given hardware scancode.
         * @returns `"unknown"` if the scancode doesn't map to a KeyConstant on the current system.
         */
        getKeyFromScancode(scancode: Scancode): KeyConstant;

        /**
         * Checks whether one at least of the provided keys is down (pressed).
         */
        isDown(...keys: KeyConstant[]): boolean;

        /**
         * Checks whether one at least of the provided scancodes is down (pressed).
         */
        isScancodeDown(...scancodes: Scancode[]): boolean;
    }
}