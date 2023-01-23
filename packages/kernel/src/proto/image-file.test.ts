import { describe, expect, it } from '@liko-12/lust';
import { loadFile, LegacyFileException, InvalidMagicTagException, UnMatchingFileTypeException, SemicolonTokenizer, InvalidTokenException, UnsupportedVersionException } from './image-file';

const testingSamples = {
    legacyImage: 'LK12;GPUIMG;2x2;\r\n08\r\n80',
    invalidFile: 'THIS IS JUST RANDOM TEXT',
    invalidFileType: 'LIKO-12;meheh-hehehe;V0;',
    invalidVersion: 'LIKO-12;IMAGE;V0;',
};

interface TestingImage {
    width: number,
    height: number,
    pixelData: number[][],
    fileName: string,
    rawData: string,
}

const testingImages: TestingImage[] = [
    {
        width: 2,
        height: 2,
        pixelData: [
            [0, 8],
            [8, 0],
        ],
        fileName: 'image_01.lk12',
        rawData: 'LIKO-12;IMAGE;V1;2x2;16-color;\r\n08\r\n80;',
    }
];

describe("kernel prototype lib 'image-file'", () => {
    const { graphics } = liko;
    if (!graphics) throw 'graphics module is not loaded!';

    describe("class 'SemicolonTokenizer'", () => {
        it("tokenize a single-line string properly", () => {
            const fileName = 'single-line.txt';
            const testingData = 'hello;world;this is;a single-line;;test;garbage_2542q5v2qq';
            const tokenizer = new SemicolonTokenizer(fileName, testingData);

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 1, content: 'hello',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 7, content: 'world',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 13, content: 'this is',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 21, content: 'a single-line',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 35, content: '',
            });


            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 36, content: 'test',
            });

            expect(tokenizer.next()).to.be(null);
            expect(tokenizer.next()).to.be(null); // Should still run fine.
        });

        it("tokenize a multi-line string properly (with LF)", () => {
            const fileName = 'multi-line-lf.txt';
            const testingData = 'hello;\nworld;from\nsecond\nline;fourth;\n;fifth;garbage_qr2fq5fqv4';
            const tokenizer = new SemicolonTokenizer(fileName, testingData);

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 1, content: 'hello',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 7, content: '\nworld',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 2, column: 7, content: 'from\nsecond\nline',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 4, column: 6, content: 'fourth',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 4, column: 13, content: '\n',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 5, column: 2, content: 'fifth',
            });

            expect(tokenizer.next()).to.be(null);
            expect(tokenizer.next()).to.be(null); // Should still run fine.
        });

        it("tokenize a multi-line string properly (with CRLF)", () => {
            const fileName = 'multi-line-crlf.txt';
            const testingData = 'hello;\r\nworld;\r\n;end;';
            const tokenizer = new SemicolonTokenizer(fileName, testingData);

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 1, content: 'hello',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 1, column: 7, content: '\r\nworld',
            });

            expect(tokenizer.next()).to.equal({
                fileName, line: 2, column: 7, content: '\r\n',
            });


            expect(tokenizer.next()).to.equal({
                fileName, line: 3, column: 2, content: 'end',
            });

            expect(tokenizer.next()).to.be(null);
            expect(tokenizer.next()).to.be(null); // Should still run fine.
        })
    })

    it("legacy files are rejected", () => {
        const [ok, err] = pcall(() => loadFile('legacy_image.lk12', testingSamples.legacyImage));

        expect(ok).to.be(false);
        expect(err instanceof LegacyFileException).to.be(true);
    });

    it("files with invalid header are rejected", () => {
        const [ok1, err1] = pcall(() => loadFile('invalid_01.lk12', testingSamples.invalidFile));
        expect(ok1).to.be(false);
        expect(err1 instanceof InvalidMagicTagException).to.be(true);

        const [ok2, err2] = pcall(() => loadFile('invalid_02.lk12', testingSamples.invalidFileType));
        expect(ok2).to.be(false);
        expect(err2 instanceof InvalidTokenException).to.be(true);

        const [ok3, err3] = pcall(() => loadFile('invalid_03.lk12', testingSamples.invalidVersion));
        expect(ok3).to.be(false);
        expect(err3 instanceof UnsupportedVersionException).to.be(true);
    });

    it("loading an image as a palette is rejected", () => {
        const [ok, err] = pcall(() => loadFile(testingImages[0].fileName, testingImages[0].rawData, 'palette'));

        expect(ok).to.be(false);
        expect(err instanceof UnMatchingFileTypeException).to.be(true);
    });

    it("testing image #0 loads", () => {
        const { fileName, rawData, width, height, pixelData } = testingImages[0];
        const imageData = loadFile(fileName, rawData, 'image');
        expect(graphics.isImageData(imageData)).to.be(true);

        expect(imageData.getWidth()).to.equal(width);
        expect(imageData.getHeight()).to.equal(height);

        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                const loadedValue = imageData.getPixel(x, y);
                const expectedValue = pixelData[y][x];

                if (loadedValue !== expectedValue)
                    throw `Expected pixel (${x}, ${y}) to be ${expectedValue} (found ${loadedValue}).`;
            }
        }
    });

    //FIXME: test invalid digits exceptions and their reported location information.
});
