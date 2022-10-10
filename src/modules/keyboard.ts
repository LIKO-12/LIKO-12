import { KeyConstant, Scancode } from "love.keyboard";

import loveEvents from "core/love-events";
import Machine from "core/machine";
import MachineModule from "core/machine-module";
import { escapedCall, validateParameters } from "core/utilities";

import Events from "modules/events";

export default class Keyboard extends MachineModule {
    constructor(machine: Machine, options: {}) {
        super(machine, options);

        const events = machine.resolveModule<Events>('events')!;

        // TODO: Document the events.

        loveEvents.on('keypressed', (key: KeyConstant, scancode: Scancode, isrepeat: boolean) => {
            events.pushEvent('keypressed', key, scancode, isrepeat);
        });

        loveEvents.on('keyreleased', (key: KeyConstant, scancode: Scancode) => {
            events.pushEvent('keyreleased', key);
        });

        loveEvents.on('textinput', (key: string) => {
            events.pushEvent('textinput', key);
        });
    }

    createAPI(_machine: Machine) {
        return {
            /**
             * Enable or disable text input events.
             * It is enabled by default on Windows, Mac, and Linux, and disabled by default on iOS and Android.
             * 
             * It would also show the on-screen keyboard for touch devices.
             */
            setTextInput: (enable: boolean) => {
                validateParameters();
                love.keyboard.setTextInput(enable);
            },

            /**
             * Get whether text input events are enabled.
             */
            hasTextInput: (): boolean => {
                return love.keyboard.hasTextInput();
            },

            /**
             * Get the hardware scancode corresponding to the given key.
             * @returns `"unknown"` if the given key has no known physical representation on the current system.
             */
            getScancodeFromKey: (key: KeyConstant): Scancode => {
                validateParameters();
                return escapedCall(love.keyboard.getScancodeFromKey, key);
            },

            /**
             * Get the key corresponding to the given hardware scancode.
             * @returns `"unknown"` if the scancode doesn't map to a KeyConstant on the current system.
             */
            getKeyFromScancode: (scancode: Scancode): KeyConstant => {
                validateParameters();
                return escapedCall(love.keyboard.getKeyFromScancode, scancode);
            },

            /**
             * Checks whether one at least of the provided keys is down (pressed).
             */
            isDown: (...keys: KeyConstant[]): boolean => {
                validateParameters();
                return love.keyboard.isDown(...keys);
            },

            /**
             * Checks whether one at least of the provided scancodes is down (pressed).
             */
            isScancodeDown: (...scancodes: Scancode[]): boolean => {
                validateParameters();
                return love.keyboard.isScancodeDown(...scancodes);
            }
        };
    }
}