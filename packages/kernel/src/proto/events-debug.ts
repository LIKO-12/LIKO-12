import { pullEvents } from 'lib/utils';

for (const [event, a, b, c, d, e, f] of pullEvents()) {
    if (event !== 'draw' && event !== 'update')
        print(event, a, b, c, d, e, f);
}