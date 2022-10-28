// https://www.lua.org/manual/5.3/manual.html#6.5

/**
 * This library provides basic support for UTF-8 encoding. It provides all its
 * functions inside the table utf8. This library does not provide any support for
 * Unicode other than the handling of the encoding. Any operation that needs the
 * meaning of a character, such as character classification, is outside its scope.
 *
 * Unless stated otherwise, all functions that expect a byte position as a
 * parameter assume that the given position is either the start of a byte
 * sequence or one plus the length of the subject string. As in the string
 * library, negative indices count from the end of the string.
 * @noSelf
 * @noResolution
 * @link [utf8](https://www.lua.org/manual/5.3/manual.html#6.5)
 */
declare module "utf8" {
    /**
     * Receives zero or more integers, converts each one to its corresponding UTF-8
     * byte sequence and returns a string with the concatenation of all these
     * sequences
     * @link [utf.char](https://www.lua.org/manual/5.3/manual.html#pdf-utf8.char)
     */
    function char(...args: Array<number>): string;
  
    /**
     * The pattern (a string, not a function) "[\0-\x7F\xC2-\xF4][\x80-\xBF]*" (see
     * §6.4.1), which matches exactly one UTF-8 byte sequence, assuming that the
     * subject is a valid UTF-8 string.
     * @link [utf.charpattern](https://www.lua.org/manual/5.3/manual.html#pdf-utf8.charpattern)
     */
    var charpattern: string;
  
    /**
     * Returns values so that the construction
     *
     * `for p, c in utf8.codes(s) do body end`
     *
     * will iterate over all characters in string s, with p being the position (in
     * bytes) and c the code point of each character. It raises an error if it meets
     * any invalid byte sequence.
     * @link [utf.codes](https://www.lua.org/manual/5.3/manual.html#pdf-utf8.codes)
     */
    function codes(s: string): any;
  
    /**
     * Returns the codepoints (as integers) from all characters in s that start between
     * byte position i and j (both included). The default for i is 1 and for j is i.
     * It raises an error if it meets any invalid byte sequence.
     * @link [utf.codepoint](https://www.lua.org/manual/5.3/manual.html#pdf-utf8.codepoint)
     */
    function codepoint(s: string, i?: number, j?: number): any;
  
    /**
     * Returns the number of UTF-8 characters in string s that start between positions
     * i and j (both inclusive). The default for i is 1 and for j is -1. If it finds
     * any invalid byte sequence, returns a false value plus the position of the first
     * invalid byte.
     * @link [utf.len](https://www.lua.org/manual/5.3/manual.html#pdf-utf8.len)
     */
    function len(s: string, i?: number, j?: number): number;
  
    /**
     * Returns the position (in bytes) where the encoding of the n-th character of s
     * (counting from position i) starts. A negative n gets characters before position
     * i. The default for i is 1 when n is non-negative and #s + 1 otherwise, so that
     * utf8.offset(s, -n) gets the offset of the n-th character from the end of the
     * string. If the specified character is neither in the subject nor right after its
     * end, the function returns _nil/null_.
     *
     * As a special case, when n is 0 the function returns the start of the encoding
     * of the character that contains the i-th byte of s.
     *
     * This function assumes that s is a valid UTF-8 string.
     * @link [utf.offset](https://www.lua.org/manual/5.3/manual.html#pdf-utf8.offset)
     */
    function offset(s: string, n?: number, i?: number): number | null;
  }