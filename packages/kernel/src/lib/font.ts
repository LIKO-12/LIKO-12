
type Image = StandardModules.Graphics.Image;

export interface Font {
    /**
     * The set of characters included in the font.
     */
    readonly characters: string,
}

interface CharacterRegion {
    srcX: number, srcY: number,
    srcWidth: number, srcHeight: number,
}

// TODO: Support colors.

export class MonospaceFont implements Font {
    private charactersRegions: Record<string, CharacterRegion> = {};

    constructor(
        private readonly image: Image,
        public readonly characterWidth: number,
        public readonly characterHeight: number,
        public readonly characters: string,
        public readonly fallbackCharacter = '?',
    ) {
        const imageWidth = image.getWidth(), imageHeight = image.getHeight();
        const columns = imageWidth / characterWidth, rows = imageHeight / characterHeight;

        if (columns !== Math.floor(columns))
            throw "The font image doesn't contain an integer count of characters columns in it's width";
        if (rows !== Math.floor(rows))
            throw "The font image doesn't contain an integer count of characters rows in it's height";

        if (fallbackCharacter.length !== 1) throw "The fallback character is not a single character";
        if (!characters.includes(fallbackCharacter)) throw "The fallback character is not included in the font's characters";

        let characterX = 0, characterY = 0;

        characters.split('').forEach((character) => {
            // Ran out of characters within the image, set them to the fallback character.
            if (characterY === imageHeight) {
                this.charactersRegions[character] = this.charactersRegions[fallbackCharacter];
                return;
            }

            this.charactersRegions[character] = {
                srcX: characterX, srcY: characterY,
                srcWidth: characterWidth, srcHeight: characterHeight,
            };

            characterX += characterWidth;
            if (characterX === imageWidth) characterX = 0, characterY += characterHeight;
        });

        if (!this.charactersRegions[fallbackCharacter]) throw "The fallback character is not included in the image";
    }

    drawCharacter(character: string, x: number, y: number): void {
        const { srcX, srcY, srcWidth, srcHeight } =
            this.charactersRegions[character] ?? this.charactersRegions[this.fallbackCharacter];
        this.image.draw(x, y, 0, 1, 1, srcX, srcY, srcWidth, srcHeight);
    }

    // TODO: Support the LF (line feed (new line)) character in both `printNoWrap` and `printWrap`.

    /**
     * Print a single line of text without any line breaking/word wrapping.
     */
    printNoWrap(text: string, x: number, y: number): void {
        const length = text.length;
        for (let position = 0; position < length; position++)
            this.drawCharacter(text[position], x, y), x += this.characterWidth;
    }
    
    // TODO: Separate the wrapping logic from the drawing logic so it can be tested and used without actually drawing.

    printWrap(text: string, x: number, y: number, width: number): void {
        const maxLineLength = Math.floor(width / this.characterWidth);

        const words = text.split(' ');
        const lines: string[][] = [];

        let currentLineLength = maxLineLength;
        for (let word of words) {
            let wordLength = word.length;

            // The word has to be braked 
            if (wordLength > maxLineLength) {
                const firstPiece = word.substring(0, maxLineLength - currentLineLength - 1);
                word = word.substring(firstPiece.length), wordLength = word.length;

                lines[lines.length - 1].push(firstPiece), currentLineLength = maxLineLength;

                while (wordLength !== 0) {
                    const piece = word.substring(0, maxLineLength), pieceLength = piece.length;

                    word = word.substring(pieceLength), wordLength = word.length;

                    lines.push([piece]), currentLineLength = pieceLength;
                }

                continue;
            }

            if (currentLineLength + 1 + wordLength > maxLineLength)
                lines.push([word]), currentLineLength = wordLength
            else
                lines[lines.length - 1].push(word), currentLineLength += 1 + wordLength
        }

        lines.map(line => line.join(' ')).forEach(line => {
            this.printNoWrap(line, x, y), y += this.characterHeight;
        });
    }

    // TODO: Split into Font and Printer.
    // Resource: https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap (has an algo)
}