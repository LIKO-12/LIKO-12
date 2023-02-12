/// <reference types="@liko-12/standard-modules-apis" />
/// <reference types="@liko-12/utf8" />
/// <reference types="lua-types/jit" />

interface LikoAPIs {
    /**
     * The screen module API if loaded.
     */
    screen?: StandardModules.ScreenAPI;

    /**
     * The keyboard module API if loaded.
     */
    keyboard?: StandardModules.KeyboardAPI;

    /**
     * The events module API if loaded.
     */
    events?: StandardModules.EventsAPI;

    /**
     * The storage module API if loaded.
     */
    storage?: StandardModules.StorageAPI;

    /**
     * The graphics module API if loaded.
     */
    graphics?: StandardModules.GraphicsAPI;
}

declare var liko: LikoAPIs;

/**
 * Starts and runs the main game loop.
 * Which is responsible for receiving the events and calling the appropriate callback function if defined.
 *  
 * A standard implementation is already provided by default.
 * 
 * Can be set to `nil`/`undefined` to prevent it from executing.
 * 
 * The function is called directly after executing the game's script.
 */
declare var _eventLoop: undefined | (() => void);