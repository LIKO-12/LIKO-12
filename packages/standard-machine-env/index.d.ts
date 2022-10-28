/// <reference types="@liko-12/standard-modules-apis" />
/// <reference types="lua-types/jit" />

/**
 * The screen module API if loaded.
 */
declare var screen: StandardModules.ScreenAPI | undefined;

/**
 * The keyboard module API if loaded.
 */
declare var keyboard: StandardModules.KeyboardAPI | undefined;

/**
 * The events module API if loaded.
 */
declare var events: StandardModules.EventsAPI | undefined;

/**
 * The storage module API if loaded.
 */
declare var storage: StandardModules.StorageAPI | undefined;
