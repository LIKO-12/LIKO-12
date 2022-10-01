import Machine from "core/machine";
import MachineModule from "core/machine-module";

export default class Graphics extends MachineModule {
    protected activeColor = 0;

    protected readonly effectsShader = this.loadEffectsShader();

    /**
     * Effective only on images, not on any shapes/geometry drawing operation.
     * 
     * 1.0 for transparent, 0.0 for opaque.
     * 
     * by default all colors are opaque except color 0.
     */
    protected readonly paletteTransparency: number[] = [1];

    protected readonly paletteRemap: number[] = [];


    constructor(machine: Machine, options: {}) {
        super(machine, options);

        // Initialize the palette remapping array.
        for (let i = 0; i < 256; i++) this.paletteRemap[i] = i;
        this.uploadPaletteTransparency();
        this.uploadPaletteRemap();

        love.graphics.setLineWidth(1);
        love.graphics.setLineJoin('miter');
        love.graphics.setLineStyle('rough');

        machine.events.on('resumed', () => this.activate());
        machine.events.on('suspended', () => this.deactivate());
    }

    activate() {
        love.graphics.setShader(this.effectsShader);
    }

    deactivate() {
        love.graphics.setShader();
    }

    private setColor(color?: number) {
        // TODO: check the range of the color.
        love.graphics.setColor((color ?? this.activeColor) / 255.0, 1, 1, 1);
    }

    createAPI(machine: Machine) {
        return {
            clear: (color?: number) => {
                love.graphics.clear((color ?? this.activeColor) / 255.0, 1, 1, 1);
            },

            rectangle: (x: number, y: number, width: number, height: number, filled = false, color?: number) => {
                this.setColor(color);
                love.graphics.rectangle(filled ? 'fill' : 'line', x, y, width, height);
            },
        };
    }

    private uploadPaletteTransparency() {
        this.effectsShader.send('u_transparent', ...this.paletteTransparency);
    }

    private uploadPaletteRemap() {
        this.effectsShader.send('u_remap', ...this.paletteRemap);
    }

    private loadEffectsShader() {
        try {
            const shader = love.graphics.newShader<{
                u_transparent: number[],
                u_remap: number[],
            }>('res/shaders/effects.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] effects shader:', warnings);

            return shader;
        } catch (error: unknown) {
            print(error);
            print('[WARNING] failed to load standard effects shader, falling back to the compatibility one.');

            const shader = love.graphics.newShader<{
                u_transparent: number[],
                u_remap: number[],
            }>('res/shaders/effects-compat.frag', 'res/shaders/default.vert');

            const warnings = shader.getWarnings();
            if (warnings !== 'vertex shader:\npixel shader:\n') print('[WARNING] effects-compat shader:', warnings);

            return shader;
        }
    }
}