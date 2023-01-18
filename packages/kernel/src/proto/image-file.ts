type ImageData = StandardModules.Graphics.ImageData;

type SupportedTypes = {
    'image': ImageData,
    'palette': [r: number, g: number, b: number][],
}

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

