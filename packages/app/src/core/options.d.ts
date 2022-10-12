/** @noSelfInFile */
import { ScreenOptions } from 'modules/screen';
import { StorageOptions } from 'modules/storage';
declare type KnownModules = 'events' | 'storage' | 'screen';
interface Options {
    window: {
        title: string;
        icon?: string | null;
        width: number;
        height: number;
        resizable: boolean;
        minWidth: number;
        minHeight: number;
        vsync: number;
        x?: number | null;
        y?: number | null;
        borderless: boolean;
        fullscreen: boolean;
        fullscreenType: string;
    };
    modules: (KnownModules | string)[];
    options: {
        screen?: ScreenOptions;
        storage?: StorageOptions;
        [key: string]: Record<string, any> | undefined;
    };
}
declare const options: Options;
export default options;
//# sourceMappingURL=options.d.ts.map