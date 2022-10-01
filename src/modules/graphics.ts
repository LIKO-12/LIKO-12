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

    createAPI(machine: Machine) {
        return {
            clear: (color?: number) => {
                love.graphics.clear(color ?? this.activeColor, 0, 0, 1);
            },

            rectangle: (x: number, y: number, width: number, height: number, filled = false, color?: number) => {
                love.graphics.setColor(color ?? this.activeColor, 0, 0, 1);
                love.graphics.rectangle(filled ? 'fill' : 'line', x, y, width, height);
            },
        };
    }
}