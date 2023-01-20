type ImageData = StandardModules.Graphics.ImageData;

type SupportedTypes = {
    'image': ImageData,
    'palette': [r: number, g: number, b: number][],
}

//#region Tokenizer

export interface Token {
    line: number,
    column: number,
    fileName: string,
    content: string,
}

/**
 * Supports both LF and CRLF.
 */
export class SemicolonTokenizer {
    /**
     * Of the last semicolon found.
     */
    private index = 0;
    /**
     * Of the last semicolon found.
     */
    private line = 1;
    /**
     * Of the last semicolon found.
     */
    private column = 1;

    private dead = false;

    constructor(
        private fileName: string,
        private rawData: string,
    ) { }

    next(): Token | null {
        if (this.dead) return null;

        const previousIndex = this.index;
        this.index = this.rawData.indexOf(';', previousIndex) + 1;

        if (this.index === 0) {
            this.destroy();
            return null; // Reached end of stream.
        }

        const token: Token = {
            line: this.line,
            column: this.column,
            fileName: this.fileName,
            content: this.rawData.substring(previousIndex, this.index - 1),
        };

        this.updateLastSemicolonLocation(token);
        return token;
    }

    /**
     * Create a token with dummy content, with the expected location of the next token.
     * Without modifying the tokenizer state in any way.
     */
    tell(): Token {
        return {
            line: this.line,
            column: this.column,
            fileName: this.fileName,
            content: '<DUMMY TOKEN created by "peek()">',
        };
    }

    private updateLastSemicolonLocation({ content }: Token) {
        let lastIndex = 0;

        while (true) {
            const index = content.indexOf('\n', lastIndex);
            if (index === -1) break;

            lastIndex = index + 1;
            this.line++;
            this.column = 1;
        }

        this.column += content.length - lastIndex + 1;
    }

    private destroy() {
        // Clear the 'rawData' field so it can free some memory.
        this.rawData = '';

        this.dead = true;
    }
}

//#endregion

//#region Exceptions

/**
 * Thrown when a `.lk12` file is rejected because it's in legacy format.
 */
export class LegacyFileException extends Error {
    constructor(public readonly fileName: string) {
        super(`${fileName}: Legacy .lk12 files are currently unsupported.`); // TODO: Support legacy .lk12 files more properly.
        this.name = 'LegacyFileException';
    }
}

/**
 * Thrown when the given file doesn't start with "LIKO-12;".
 */
export class InvalidMagicTagException extends Error {
    constructor(public readonly fileName: string) {
        super(`${fileName}: This is not a standard .lk12 file.`);
        this.name = 'InvalidMagicTagException';
    }
}

export class TokenError extends Error {
    public readonly line: number;
    public readonly column: number;
    public readonly fileName: string;
    public readonly plainMessage: string;

    constructor({ line, column, fileName }: Token, message: string) {
        super(`${fileName}:${line}:${column}: ${message}`);
        this.name = 'TokenError';

        this.line = line, this.column = column, this.fileName = fileName;
        this.plainMessage = message;
    }
}

export class MissingTokenException extends TokenError {
    /**
     * @param tokenDescriptor A string explaining what the expected token would be. (ex: `'file type'`).
     */
    constructor(
        tokenizer: SemicolonTokenizer,
        tokenDescriptor: string,
    ) {
        super(tokenizer.tell(), `Expected ${tokenDescriptor} (found nothing instead).`);
        this.name = 'MissingTokenException';
    }
}

/**
 * Thrown when the give file doesn't contain the requested content type.
 */
export class UnMatchingFileTypeException extends TokenError {
    constructor(
        token: Token,
        public readonly detectedType: string,
        public readonly expectedType: string,
    ) {
        super(token, `Expected '${expectedType}' content type (found '${detectedType.toLowerCase()}' instead).`);
        this.name = 'UnMatchingFileTypeException';
    }
}

//#endregion

export function loadFile<T extends keyof SupportedTypes>(fileName: string, rawData: string, fileType: T): SupportedTypes[T];
export function loadFile(fileName: string, rawData: string): SupportedTypes[keyof SupportedTypes]
export function loadFile(fileName: string, rawData: string, fileType?: keyof SupportedTypes): SupportedTypes[keyof SupportedTypes] {
    if (rawData.substring(0, 5) === 'LK12;') throw new LegacyFileException(fileName);

    if (!rawData.startsWith("LIKO-12;")) throw new InvalidMagicTagException(fileName);

    const tokenizer = new SemicolonTokenizer(fileName, rawData);
    if (tokenizer.next()?.content !== 'LIKO-12') throw new InvalidMagicTagException(fileName);
    
    const fileTypeToken = tokenizer.next();
    if (!fileTypeToken) throw new MissingTokenException(tokenizer, 'file type'); // FIXME: next() should not return null, but instead throw this error.
    const rawFileType = fileTypeToken.content;

    const versionNumberToken = tokenizer.next();
    if (!versionNumberToken) throw new MissingTokenException(tokenizer, 'version number');
    const versionNumber = versionNumberToken.content;

    // const [rawFileType, versionNumber] = string.match(rawData, "^LIKO%-12;([A-Z_]+);V(%d+);");
    // if (!rawFileType || versionNumber !== 'V1') throw new InvalidMagicTagException(fileName);

    const isBinary = rawFileType.endsWith('_BIN');
    const detectedFileType = isBinary ? rawFileType.substring(0, rawFileType.length - 4) : rawFileType;

    if (fileType !== undefined && fileType.toUpperCase() !== detectedFileType)
        throw new UnMatchingFileTypeException(fileTypeToken, detectedFileType, fileType);

    throw "unimplemented"; // FIXME: Implement this.
}

