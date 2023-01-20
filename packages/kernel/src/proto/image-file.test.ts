import { describe, expect, it } from '@liko-12/lust';
import { loadFile, LegacyFileException, NonStandardFileException, UnMatchingFileTypeException, SemicolonTokenizer } from './image-file';

const testingSamples = {
    legacyImage: 'LK12;GPUIMG;2x2;\r\n08\r\n80',
    invalidFile: 'THIS IS JUST RANDOM TEXT',
};

interface TestingImage {
    width: number,
    height: number,
    pixelData: number[][],
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
        rawData: 'LIKO-12;IMAGE;V1;2x2;16-color;\r\n08\r\n80;',
    }
];

describe("kernel prototype lib 'image-file'", () => {
    const { graphics } = liko;
    if (!graphics) throw 'graphics module is not loaded!';

    describe("class 'SemicolonTokenizer'", () => {
        it("tokenize a single-line string properly", () => {
            const testingData = 'hello;world;this is;a single-line;;test;garbage_2542q5v2qq';
            const tokenizer = new SemicolonTokenizer(testingData);

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 1, content: 'hello',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 7, content: 'world',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 13, content: 'this is',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 21, content: 'a single-line',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 35, content: '',
            });


            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 36, content: 'test',
            });

            expect(tokenizer.getNextToken()).to.be(null);
            expect(tokenizer.getNextToken()).to.be(null); // Should still run fine.
        });

        it("tokenize a multi-line string properly (with LF)", () => {
            const testingData = 'hello;\nworld;from\nsecond\nline;fourth;\n;fifth;garbage_qr2fq5fqv4';
            const tokenizer = new SemicolonTokenizer(testingData);

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 1, content: 'hello',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 7, content: '\nworld',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 2, column: 7, content: 'from\nsecond\nline',
            });
            
            expect(tokenizer.getNextToken()).to.equal({
                line: 4, column: 6, content: 'fourth',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 4, column: 13, content: '\n',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 5, column: 2, content: 'fifth',
            });

            expect(tokenizer.getNextToken()).to.be(null);
            expect(tokenizer.getNextToken()).to.be(null); // Should still run fine.
        });

        it("tokenize a multi-line string properly (with CRLF)", () => {
            const testingData = 'hello;\r\nworld;\r\n;end;';
            const tokenizer = new SemicolonTokenizer(testingData);

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 1, content: 'hello',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 1, column: 7, content: '\r\nworld',
            });

            expect(tokenizer.getNextToken()).to.equal({
                line: 2, column: 7, content: '\r\n',
            });


            expect(tokenizer.getNextToken()).to.equal({
                line: 3, column: 2, content: 'end',
            });

            expect(tokenizer.getNextToken()).to.be(null);
            expect(tokenizer.getNextToken()).to.be(null); // Should still run fine.
        })
    })

    it("legacy files are rejected", () => {
        const [ok, err] = pcall(() => loadFile(testingSamples.legacyImage));

        expect(ok).to.be(false);
        expect(err instanceof LegacyFileException).to.be(true);
    });

    it("files with invalid header are rejected", () => {
        const [ok, err] = pcall(() => loadFile(testingSamples.invalidFile));

        expect(ok).to.be(false);
        expect(err instanceof NonStandardFileException).to.be(true);
    });

    it("loading an image as a palette is rejected", () => {
        const [ok, err] = pcall(() => loadFile(testingImages[0].rawData, 'palette'));

        expect(ok).to.be(false);
        expect(err instanceof UnMatchingFileTypeException).to.be(true);
    });

    it("testing image #0 loads", () => {
        const imageData = loadFile(testingImages[0].rawData, 'image');
        expect(graphics.isImageData(imageData)).to.be(true);
    });
});
