/**
 * Bootstraps the standard LIKO-12 application which runs a single machine.
 */

import options from 'core/options';
import loveEvents from 'core/love-events';
import Machine from 'core/machine';

loveEvents.on('load', () => {
    new Machine(options.modules, options.options);
});
