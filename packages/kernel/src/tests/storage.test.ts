import { describe, it, expect } from '@liko-12/lust';
import { assert } from 'lib/utils';

type FileStream = StandardModules.Storage.FileStream;
type FileMode = StandardModules.Storage.FileMode;
type FileInfo = StandardModules.Storage.FileInfo;

describe("'liko.storage' module", () => {
    const storage = liko.storage!;
    it('is loaded', () => expect(storage).to.exist());

    math.randomseed(1122332211); // use a deterministic seed.

    function generateFilename() {
        return tostring(math.random(1_000_000_000, 9_999_999_999));
    }

    function open(path: string, mode: FileMode = 'w') {
        return assert<FileStream>(...storage.open(path, mode));
    }

    it('valid space usage metrics', () => {
        const totalSpace = storage.getTotalSpace();
        const usedSpace = storage.getUsedSpace();
        const availableSpace = storage.getAvailableSpace();

        expect(totalSpace).to.be.a('number');
        expect(usedSpace).to.be.a('number');
        expect(availableSpace).to.be.a('number');

        expect(totalSpace >= 0).to.be.truthy();
        expect(usedSpace >= 0).to.be.truthy();
        expect(availableSpace >= 0).to.be.truthy();

        expect(totalSpace === Math.floor(totalSpace)).to.be.truthy();
        expect(usedSpace === Math.floor(usedSpace)).to.be.truthy();
        expect(availableSpace === Math.floor(availableSpace)).to.be.truthy();

        expect(usedSpace + availableSpace === availableSpace).to.be.truthy();
    });

    it('directory operations', () => {
        const path = generateFilename();

        expect(() => assert(...storage.getInfo(path))).to.fail();

        // parent directory should be automatically created.
        assert(...storage.createDirectory(`${path}/${path}`));

        const info = assert<FileInfo>(...storage.getInfo(path));
        expect(info.type).to.be('directory');
        expect(info.size).to.be(0);
        expect(info.modtime).to.be.a('number');

        const content = assert<string[]>(...storage.readDirectory(path));
        expect(content).to.equal([path]);

        expect(() => assert(...storage.deleteDirectory(path))).to.fail();

        assert(...storage.deleteDirectory(`${path}/${path}`));
        assert(...storage.deleteDirectory(path));

        expect(() => assert(...storage.getInfo(path))).to.fail();
    });

});