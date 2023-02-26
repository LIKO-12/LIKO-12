import type { EffectsAPI } from './effects-api';
import type { ShapesAPI } from './shapes-api';
import type { ImagesAPI } from './images-api';

export * from './effects-api';
export * from './shapes-api';
export * from './images-api';

export interface GraphicsAPI extends ShapesAPI, EffectsAPI, ImagesAPI {
}