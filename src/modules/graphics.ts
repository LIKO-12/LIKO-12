import Machine from "core/machine";
import MachineModule from "core/machine-module";

export default class Graphics extends MachineModule {
    protected activeColor = 0;

    constructor(machine: Machine, options: {}) {
        super(machine, options);

        love.graphics.setLineWidth(1);
        love.graphics.setLineJoin('miter');
        love.graphics.setLineStyle('rough');
    }

    private setColor(color?: number) {
        // TODO: check the range of the color.
        love.graphics.setColor((color ?? this.activeColor) / 255.0, 0, 0, 1);
    }

    createAPI(machine: Machine) {
        return {
            clear: (color?: number) => {
                love.graphics.clear((color ?? this.activeColor) / 255.0, 0, 0, 1);
            },

            rectangle: (x: number, y: number, width: number, height: number, filled = false, color?: number) => {
                this.setColor(color);
                love.graphics.rectangle(filled ? 'fill' : 'line', x, y, width, height);
            },
        };
    }
}