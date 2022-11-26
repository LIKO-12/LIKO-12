import { describe, it, expect } from '@liko-12/lust';

type FileMode = StandardModules.Storage.FileMode;

// TODO: Further more extensive unit tests for the storage module.

describe("liko 'storage' module", () => {
    const storage = liko.storage!;
    it('is loaded', () => expect(storage).to.exist());

    math.randomseed(1122332211); // use a deterministic seed.

    function generateFilename() {
        return tostring(math.random(1_000_000_000, 9_999_999_999));
    }

    it('basic file operations', () => {
        const path = generateFilename();

        // get info of a non-existing file.
        expect(() => storage.getInfo(path)).to.fail();

        // create a file with simple content.
        {
            const file = storage.open(path, 'w');
            expect(file.seek()).to.be(0);
            file.write(path);
            expect(file.seek()).to.be(path.length);
            file.flush();
            file.close();
        }

        // verify information of the created file.
        {
            const info = storage.getInfo(path);
            expect(info.type).to.be('file');
            expect(info.size).to.be(path.length);
            expect(info.modtime).to.be.a('number');
        }

        // read content of the created file.
        {
            const file = storage.open(path, 'r');
            expect(file.seek()).to.be(0);
            expect(file.read()).to.be(path);
            expect(file.seek()).to.be(path.length);
            file.close();
        }

        // append content to the created file.
        {
            const file = storage.open(path, 'a');
            expect(file.seek()).to.be(path.length);
            file.write(path);
            expect(file.seek()).to.be(path.length * 2);
            file.flush();
            file.close()
        }

        // verify the information of the file after being updated.
        {
            const info = storage.getInfo(path);
            expect(info.type).to.be('file');
            expect(info.size).to.be(path.length * 2);
            expect(info.modtime).to.be.a('number');
        }

        // verify the content of the file after being updated.
        {
            const file = storage.open(path, 'r');
            expect(file.seek()).to.be(0);
            expect(file.read()).to.be(`${path}${path}`);
            expect(file.seek()).to.be(path.length * 2);
            file.close()
        }

        // delete the file.
        storage.removeFile(path)

        // deleting a non-existing file should fail.
        expect(() => storage.removeFile(path)).to.fail();
    });

    it('directory operations', () => {
        const path = generateFilename();

        // get info of a non-existing directory.
        expect(() => storage.getInfo(path)).to.fail();

        // parent directory should be automatically created.
        storage.createDirectory(`${path}/${path}`);

        // directory already created.
        expect(() => storage.createDirectory(`${path}/${path}`)).to.fail();

        // verify file info.
        const info = storage.getInfo(path);
        expect(info.type).to.be('directory');
        expect(info.size).to.be(0);
        expect(info.modtime).to.be.a('number');

        // verify directory content.
        const content = storage.readDirectory(path);
        expect(content).to.equal([path]);

        // deleting a directory using the normal file deletion should fail.
        expect(() => storage.removeFile(`${path}/${path}`)).to.fail();

        // deleting a non-empty directory should fail.
        expect(() => storage.removeDirectory(path)).to.fail();

        // remove the created directories properly.
        storage.removeDirectory(`${path}/${path}`);
        storage.removeDirectory(path);

        // getting file info of non-existing ones should fail.
        expect(() => storage.getInfo(path)).to.fail();

        // deleting a non-existing directory.
        expect(() => storage.removeDirectory(path)).to.fail();
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