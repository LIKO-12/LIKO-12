import type { GraphicsAPI, ScreenAPI } from './modules';

declare global {
    /**
     * @transformer_globalize Hint for the 'ts-globalize' transformer to take action on this interface.
     */
    interface LikoGlobalized extends GraphicsAPI, ScreenAPI { }
}