import { KeyboardAPI, KeyConstant, Scancode } from '@liko-12/standard-modules-types';

import { loveEvents } from 'core/love-events';
import { Machine } from "core/machine";
import { MachineModule } from "core/machine-module";
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
            events.pushEvent('keyreleased', key, scancode);
        });

        loveEvents.on('textinput', (key: string) => {
            events.pushEvent('textinput', key);
        });
    }

    createAPI(_machine: Machine): KeyboardAPI {
        return {
            setTextInput: (enable: boolean) => {
                validateParameters();
                love.keyboard.setTextInput(enable);
            },

            hasTextInput: (): boolean => {
                return love.keyboard.hasTextInput();
            },

            getScancodeFromKey: (key: KeyConstant): Scancode => {
                validateParameters();
                return escapedCall(love.keyboard.getScancodeFromKey, key);
            },

            getKeyFromScancode: (scancode: Scancode): KeyConstant => {
                validateParameters();
                return escapedCall(love.keyboard.getKeyFromScancode, scancode);
            },

            isDown: (...keys: KeyConstant[]): boolean => {
                validateParameters();
                return love.keyboard.isDown(...keys);
            },

            isScancodeDown: (...scancodes: Scancode[]): boolean => {
                validateParameters();
                return love.keyboard.isScancodeDown(...scancodes);
            }
        };
    }
}