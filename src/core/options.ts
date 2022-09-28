import * as rawOptions from 'options.json';

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
    }
}

const options: Options = rawOptions;
export default options;