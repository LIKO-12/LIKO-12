import { describe, it, expect } from '@liko-12/lust';
import { assert } from 'lib/utils';

type FileStream = StandardModules.Storage.FileStream;
type FileMode = StandardModules.Storage.FileMode;
type FileInfo = StandardModules.Storage.FileInfo;

// TODO: Further more extensive unit tests for the storage module.

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

    it('basic file operations', () => {
        const path = generateFilename();

        // get info of a non-existing file.
        expect(() => assert(...storage.getInfo(path))).to.fail();

        // create a file with simple content.
        {
            const file = open(path, 'w');
            assert(...file.write(path));
            assert(...file.flush());
            assert(file.close());
        }

        // verify information of the created file.
        {
            const info = assert<FileInfo>(...storage.getInfo(path));
            expect(info.type).to.be('file');
            expect(info.size).to.be(path.length);
            expect(info.modtime).to.be.a('number');
        }

        // read content of the created file.
        {
            const file = open(path, 'r');
            expect(assert(...file.read())).to.be(path);
            file.close();
        }

        // append content to the created file.
        {
            const file = open(path, 'a');
            assert(...file.write(path));
            assert(...file.flush());
            assert(file.close());
        }

        // verify the information of the file after being updated.
        {
            const info = assert<FileInfo>(...storage.getInfo(path));
            expect(info.type).to.be('file');
            expect(info.size).to.be(path.length * 2);
            expect(info.modtime).to.be.a('number');
        }

        // verify the content of the file after being updated.
        {
            const file = open(path, 'r');
            expect(assert(...file.read())).to.be(`${path}${path}`);
            assert(file.close());
        }

        // delete the file.
        assert(...storage.delete(path))

        // deleting a non-existing file should fail.
        expect(() => assert(...storage.delete(path))).to.fail();
    });

    it('directory operations', () => {
        const path = generateFilename();

        // get info of a non-existing directory.
        expect(() => assert(...storage.getInfo(path))).to.fail();

        // parent directory should be automatically created.
        assert(...storage.createDirectory(`${path}/${path}`));

        // directory already created.
        expect(() => assert(...storage.createDirectory(`${path}/${path}`))).to.fail();

        // verify file info.
        const info = assert<FileInfo>(...storage.getInfo(path));
        expect(info.type).to.be('directory');
        expect(info.size).to.be(0);
        expect(info.modtime).to.be.a('number');

        // verify directory content.
        const content = assert<string[]>(...storage.readDirectory(path));
        expect(content).to.equal([path]);

        // deleting a directory using the normal file deletion should fail.
        expect(() => assert(...storage.delete(`${path}/${path}`))).to.fail();

        // deleting a non-empty directory should fail.
        expect(() => assert(...storage.deleteDirectory(path))).to.fail();

        // remove the created directories properly.
        assert(...storage.deleteDirectory(`${path}/${path}`));
        assert(...storage.deleteDirectory(path));
        
        // getting file info of non-existing ones should fail.
        expect(() => assert(...storage.getInfo(path))).to.fail();
        
        // deleting a non-existing directory.
        expect(() => assert(...storage.deleteDirectory(path))).to.fail();
    });

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

        expect(usedSpace + availableSpace === totalSpace).to.be.truthy();
    });

});