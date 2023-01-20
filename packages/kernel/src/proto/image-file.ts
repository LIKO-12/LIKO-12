type ImageData = StandardModules.Graphics.ImageData;

type SupportedTypes = {
    'image': ImageData,
    'palette': [r: number, g: number, b: number][],
}

export interface Token {
    line: number,
    column: number,
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
        private rawData: string,
    ) { }

    getNextToken(): Token | null {
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
            content: this.rawData.substring(previousIndex, this.index - 1),
        };

        this.updateLastSemicolonLocation(token);
        return token;
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

//#region Exceptions

/**
 * Thrown when a `.lk12` file is rejected because it's in legacy format.
 */
export class LegacyFileException extends Error {
    constructor() {
        super("Legacy .lk12 files are currently unsupported."); // TODO: Support legacy .lk12 files more properly.
    }
}

/**
 * Thrown when the given file doesn't contain the standard `.lk12` file header.
 */
export class NonStandardFileException extends Error {
    constructor() {
        super("This is not a standard .lk12 file.");
    }
}

/**
 * Thrown when the give file doesn't contain the requested content type.
 */
export class UnMatchingFileTypeException extends Error {
    constructor(detectedType: string, expectedType: string) {
        super(`The file doesn't contain '${expectedType}' data (found '${detectedType.toLowerCase()}' instead).`);
    }
}

//#endregion

export function loadFile<T extends keyof SupportedTypes>(rawData: string, fileType: T): SupportedTypes[T];
export function loadFile(rawData: string): SupportedTypes[keyof SupportedTypes]
export function loadFile(rawData: string, fileType?: keyof SupportedTypes): SupportedTypes[keyof SupportedTypes] {
    if (rawData.substring(0, 5) === 'LK12;') throw new LegacyFileException();

    const [rawFileType, versionNumber] = string.match(rawData, "^LIKO%-12;([A-Z_]+);V(%d+);");
    if (!rawFileType || versionNumber !== '1') throw new NonStandardFileException();

    const isBinary = rawFileType.endsWith('_BIN');
    const detectedFileType = isBinary ? rawFileType.substring(0, rawFileType.length - 4) : rawFileType;

    if (fileType !== undefined && fileType.toUpperCase() !== detectedFileType)
        throw new UnMatchingFileTypeException(detectedFileType, fileType);

    throw "unimplemented"; // FIXME: Implement this.
}

