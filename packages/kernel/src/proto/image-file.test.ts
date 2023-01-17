import { describe, expect, it } from '@liko-12/lust';
import { loadFile, LegacyFileException, NonStandardFileException, UnMatchingFileTypeException } from './image-file';

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
        rawData: 'LIKO-12;IMAGE_BIN;2x2;16-color;\r\n08\r\n80;',
    }
];

describe("kernel prototype lib 'image-file'", () => {
    const { graphics } = liko;
    if (!graphics) throw 'graphics module is not loaded!';

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
