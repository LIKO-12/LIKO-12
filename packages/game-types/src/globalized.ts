import type { GraphicsAPI, ScreenAPI } from './modules';
import type {
    ImageData as _ImageData,
    Image as _Image,
    PixelFunction as _PixelFunction,
    KeyConstant as _KeyConstant,
    Scancode as _Scancode,
} from './modules';

declare global {
    type Image = _Image;
    type PixelFunction = _PixelFunction;
    type KeyConstant = _KeyConstant;
    type Scancode = _Scancode;

    // Necessary for the transformer generated declarations to be valid.
    type ImageData = _ImageData;

    /**
     * @transformer_globalize Hint for the 'ts-globalize' transformer to take action on this interface.
     */
    interface LikoGlobalized extends GraphicsAPI, ScreenAPI { }
}