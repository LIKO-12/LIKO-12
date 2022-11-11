import { describe, it, expect } from '@liko-12/lust';

import { assert } from 'lib/utils';

function testIOModule(io: typeof _G['io']) {
    it('io is defined', () => expect(io).to.exist());

    function open(path: string, mode = 'r'): LuaFile {
        return assert<LuaFile>(...io.open(path, mode));
    }

    describe('io.open', () => {

        it('write to "test_suite.txt"', () => {
            const file = open('test_suite.txt', 'w');
            assert(file.write('Hello from the test suite'));
            assert(file.close());
        });

        // it('"test_suite.txt" should exist', () => {
        //     expect(assert(storage.getInfo('test_suite.txt'))).to.be.truthy()
        // });

        it('delete "test_suite.txt', () => {
            // assert(storage.delete('test_suite.txt'));
        });

    });
}

// Tested only when running in debug mode.
// TODO: Add "skipped" tests status.
if (debug !== undefined) {
    describe("standard 'io' module", () => {
        it('debug module is loaded', () => expect(debug).to.exist());

        const io = debug.getfenv(debug.debug)['io'];
        it('sandbox escaped', () => expect('io').to.exist());

        testIOModule(io);
    });
}

describe("'io' module", () => {    
    const storage = liko.storage!;
    it('storage module is loaded', () => expect(storage).to.exist());

    testIOModule(io);
});