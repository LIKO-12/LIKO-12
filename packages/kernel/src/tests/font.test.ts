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

    let font: MonospaceFont | null = null;

    it('create testing font', () => {
        font = createTestingFont();
    });

    it('draw a single character', () => {
        if (!font) throw 'the testing font has not been loaded!';
        font.drawCharacter('A', 2, 2);
    });

    it('print a single line with no wrapping', () => {
        if (!font) throw 'the testing font has not been loaded!';
        font.printNoWrap("AABBBAACCCDD HELLO WORLD!", 2, 2 + font.characterHeight * 1);
    });

    it('print a long line with word wrapping', () => {
        if (!font) throw 'the testing font has not been loaded!';
        font.printWrap(
            'AAA BBB AAA BBB CCC BBAABBAABBAABBAABB',
            2, 2 + font.characterHeight * 2,
            font.characterWidth * 7,
        );
    });
});
