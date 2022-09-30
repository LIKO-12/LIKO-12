import { ScreenOptions } from 'modules/screen';
import * as rawOptions from 'options.json';

type KnownModules = 'events' | 'storage' | 'screen';

interface Options {
    window: {
        title: string,
        icon?: string | null,
        width: number,
        height: number,
        resizable: boolean,
        minWidth: number,
        minHeight: number,
        vsync: number,
        x?: number | null,
        y?: number | null,
        borderless: boolean,
        fullscreen: boolean,
        fullscreenType: string,
    },
    modules: (KnownModules | string)[],
    options: {
        screen?: ScreenOptions,
        storage?: {
            capacity: number,
            basePath: string,
        },

        [key: string]: Record<string, any> | undefined,
    }
}

const options: Options = rawOptions;
export default options;