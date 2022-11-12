import { describe, it, expect } from '@liko-12/lust';

import { assert } from 'lib/utils';

type NecessaryOSLib = Pick<typeof _G['os'], 'remove'>;

function testIOModule(io: typeof _G['io'], os: NecessaryOSLib) {
    it('io is defined', () => expect(io).to.exist());

    function open(path: string, mode: string): LuaFile {
        return assert<LuaFile>(...io.open(path, mode));
    }

    describe('io.open', () => {
        const path = 'test_suite.txt';

        it('is defined', () => expect(io.open).to.be.a('function'));

        it('basic write operation', () => {
            const file = open(path, 'w');
            expect(`${file}`).to.match('^file %(0x%x+%)$');

            expect(assert(...file.seek())).to.be(0);
            assert(...file.write(path));
            expect(assert(...file.seek())).to.be(path.length);

            assert(file.flush(), 'failed to flush');
            assert(file.close(), 'failed to close');

            expect(`${file}`).to.be('file (closed)');

            // writing should fail after being closed.
            expect(() => assert(...file.write(path))).to.fail();

            expect(() => file.flush()).to.fail();
            expect(() => file.close()).to.fail();
        });

        it('basic append operation', () => {
            const file = open(path, 'a');
            expect(`${file}`).to.match('^file %(0x%x+%)$');

            // the standard io has this odd behavior in which it has to be manually seeked
            // to the end to tell the right position.
            // although it does that automatically before any write operation.

            expect(assert(...file.seek('end', 0))).to.be(path.length);
            assert(...file.write(path));
            expect(assert(...file.seek())).to.be(path.length * 2);

            assert(file.flush(), 'failed to flush');
            assert(file.close(), 'failed to close');

            expect(`${file}`).to.be('file (closed)');

            // writing should fail after being closed.
            expect(() => assert(...file.write(path))).to.fail();

            expect(() => file.flush()).to.fail();
            expect(() => file.close()).to.fail();
        });

        it('basic read operation', () => {
            const file = open(path, 'r');
            expect(`${file}`).to.match('^file %(0x%x+%)$');

            expect(assert(...file.seek())).to.be(0);
            expect(file.read('*a')).to.be(`${path}${path}`);
            expect(assert(...file.seek())).to.be(path.length * 2);

            assert(file.close(), 'failed to close');

            expect(`${file}`).to.be('file (closed)');

            // reading should fail after being closed.
            expect(() => assert(file.read(0))).to.fail();

            expect(() => file.flush()).to.fail();
            expect(() => file.close()).to.fail();
        });

        it('cleanup', () => {
            assert(os.remove(path));
        });
    });
}

// Tested only when running in debug mode.
// TODO: Add "skipped" tests status.

describe("standard 'io' module", () => {
    if (debug !== undefined) {
        it('debug module is loaded', () => expect(debug).to.exist());

        const { io, os } = debug.getfenv(debug.debug);

        it('sandbox escaped', () => {
            expect(io).to.exist();
            expect(os).to.exist();
        });

        testIOModule(io, os);
    } else {
        it('skipped due to not running in debug mode.', () => expect(debug).to_not.exist());
        it('add the --debug command-line option to fix.', () => expect(debug).to_not.exist());
    }
});


describe("emulated 'io' module", () => {    
    const storage = liko.storage!;
    it('storage module is loaded', () => expect(storage).to.exist());

    const os: NecessaryOSLib = {
        remove: (filename: string): LuaMultiReturn<[undefined, string] | [true]> => {
            const [success, message] = storage.delete(filename);

            if (success) return $multi(true);
            else return $multi(undefined, `${message}`);
        }
    };

    testIOModule(io, os);
});