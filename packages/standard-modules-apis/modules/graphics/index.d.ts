/// <reference path="./shapes-api.d.ts" />
/// <reference path="./effects-api.d.ts" />
/// <reference path="./images-api.d.ts" />

/// <reference path="./image.d.ts" />
/// <reference path="./image-data.d.ts" />

declare namespace StandardModules {
    export interface GraphicsAPI extends Graphics.ShapesAPI, Graphics.EffectsAPI, Graphics.ImagesAPI {
    }
}