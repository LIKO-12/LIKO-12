/// <reference types="@liko-12/utf8" />
/// <reference types="lua-types/jit" />

import type { ScreenAPI, KeyboardAPI, EventsAPI, StorageAPI, GraphicsAPI } from '.';

declare global {
    /**
     * The LIKO-12 provided API.
     */
    var liko: {
        /**
         * The screen module API if loaded.
         */
        screen: ScreenAPI;

        /**
         * The keyboard module API if loaded.
         */
        keyboard?: KeyboardAPI;

        /**
         * The events module API if loaded.
         */
        events: EventsAPI;

        /**
         * The storage module API if loaded.
         */
        storage?: StorageAPI;

        /**
         * The graphics module API if loaded.
         */
        graphics: GraphicsAPI;
    };

    /**
     * @transformer_globalize Hint for the 'ts-globalize' transformer to take action on this interface.
     */
    interface LIKO_GLOBAL extends GraphicsAPI, ScreenAPI { }

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
    var _eventLoop: undefined | (() => void);
}