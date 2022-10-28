// TODO: Create eslint rule to enforce `this: void` to be in all methods in this package.

/// <reference path="./constants/keys.d.ts" />
/// <reference path="./constants/scancodes.d.ts" />

/// <reference path="./modules/screen.d.ts" />
/// <reference path="./modules/keyboard.d.ts" />
/// <reference path="./modules/events.d.ts" />

declare module "@liko-12/standard-modules-apis" {
    export type KeyConstant = StandardModules.KeyConstant;
    export type Scancode = StandardModules.Scancode;

    export type EventsAPI = StandardModules.EventsAPI;
    export type KeyboardAPI = StandardModules.KeyboardAPI;
    export type ScreenAPI = StandardModules.ScreenAPI;
}
