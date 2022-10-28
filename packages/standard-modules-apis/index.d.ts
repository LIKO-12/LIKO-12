// TODO: Create eslint rule to enforce `this: void` to be in all methods in this package.
// TODO: Create eslint rule to enforce documenting the APIs.

/// <reference path="./constants/keys.d.ts" />
/// <reference path="./constants/scancodes.d.ts" />

/// <reference path="./modules/screen.d.ts" />
/// <reference path="./modules/keyboard.d.ts" />
/// <reference path="./modules/events.d.ts" />
/// <reference path="./modules/storage.d.ts" />

declare module "@liko-12/standard-modules-apis" {
    export type KeyConstant = StandardModules.KeyConstant;
    export type Scancode = StandardModules.Scancode;

    export type EventsAPI = StandardModules.EventsAPI;
    export type KeyboardAPI = StandardModules.KeyboardAPI;
    export type ScreenAPI = StandardModules.ScreenAPI;
    export type StorageAPI = StandardModules.StorageAPI;
    
    export type FileMode = StandardModules.FileMode;
    export type FileInfo = StandardModules.FileInfo;
    export type FileStream = StandardModules.FileStream;
}
