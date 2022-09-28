/**
 * WARNING: this is INCOMPLETE typing of the library.
 */

interface DecodeOptions {
    /**
     * @default false
     */
    strictParsing?: boolean;
}

interface EncodeOptions {
    /**
     * turn pretty formatting on
     * @default false
     */
    pretty?: boolean;
    /**
     * use this indent for each level of an array/object
     */
    indent?: string;
    /**
     * if true, align the keys in a way that sounds like it should be nice, but is actually ugly
     */
    align_keys?: boolean;
    /**
     * if true, array elements become one to a line rather than inline
     */
    array_newline?: boolean;

    /**
     * @default undefined
     */
    null?: any;
    /**
     * if set to true, consider Lua strings not as a sequence of bytes,
     * but as a sequence of UTF-8 characters.
     * 
     * @default false
     */
    stringsAreUtf8?: boolean;
}

interface L_JSON {
    decode(rawJson: string, etc?: any, options?: DecodeOptions): any;
    
    encode(value: any, etc?: any, options?: EncodeOptions): string;
    encode_pretty(value: any, etc?: any, options?: EncodeOptions): string;

    /**
     * @default false
     */
    strictParsing: boolean;
    /**
     * @default false
     */
    decodeNumbersAsObjects: boolean;
}

declare const json: L_JSON;
export default json;