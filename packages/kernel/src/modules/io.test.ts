import { describe, it, expect } from '@liko-12/lust';

import { assert } from 'lib/utils';

function open(path: string, mode = 'r'): LuaFile {
    return assert<LuaFile>(...io.open(path, mode));
}

describe("'io' module", () => {
    const storage = liko.storage!;
    expect(storage).to.exist();

    it('is defined', () => expect(io).to.exist());

    describe('io.open', () => {

        it('write to "test_suite.txt"', () => {
            const file = open('test_suite.txt', 'w');
            assert(file.write('Hello from the test suite'));
            assert(file.close());
        });

        it('"test_suite.txt" should exist', () => {
            expect(assert(storage.getInfo('test_suite.txt'))).to.be.truthy()
        });

        it('delete "test_suite.txt', () => {
            // assert(storage.delete('test_suite.txt'));
        });

    });

});