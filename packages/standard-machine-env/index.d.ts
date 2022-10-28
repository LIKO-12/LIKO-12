/// <reference types="@liko-12/standard-modules-apis" />
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