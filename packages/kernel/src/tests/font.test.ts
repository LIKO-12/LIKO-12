import { describe, it, expect } from '@liko-12/lust';
import { Font, MonospaceFont } from 'lib/font';

type Image = StandardModules.Graphics.Image;

const testingFontRawPixelData = `
 ..  ...   ... ...       .... 
.  . .  . .    .  .         . 
.... ...  .    .  .       ... 
.  . .  . .    .  .           
.  . ...   ... ...        ..  
                              
`;

const testingFontCharacterWidth = 5, testingFontCharacterHeight = 6;
const testingFontCharacters = 'ABCD ?', testingFontFallbackCharacter = '?';

function createTestingFontImage(): Image {
    const { graphics } = liko;
    if (!graphics) throw 'graphics module is not loaded!';

    const pixels = testingFontRawPixelData
        .replaceAll('\r', '')
        .split('\n')
        .filter(line => line.length !== 0)
        .map(line => line.split(''));

    const imageData = graphics.newImageData(pixels[0].length, pixels.length);
    imageData.mapPixels((x, y) => pixels[y]?.[x] === ' ' ? 0 : 7);

    return imageData.toImage();
}

function createTestingFont(): MonospaceFont {
    return new MonospaceFont(
        createTestingFontImage(),
        testingFontCharacterWidth,
        testingFontCharacterHeight,
        testingFontCharacters,
        testingFontFallbackCharacter,
    );
}

describe("kernel lib 'font'", () => {
    const { graphics } = liko;
    if (!graphics) throw 'graphics module is not loaded!';

    it('create testing font', () => {
        const font = createTestingFont();
        font.drawCharacter('L', 2, 2);

        font.printNoWrap("AABBBAACCCDD HELLO WORLD!", 2, 10);
    });
});
