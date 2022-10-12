/// <reference types="@typescript-to-lua/language-extensions" />
/** @noSelfInFile */
import { File } from "love.filesystem";
import Storage, { TextFileMode } from ".";
/**
 * File object for reading and writing into a file.
 *
 * Close to standard Lua `io` files in functionality.
 * With deference mainly in:
 *  - files are in binary `b` mode by default.
 *  - `file:read` only accepts bytes count.
 *  - `file:lines` is not implemented.
 *  - possibly some difference in error messages.
 */
export default class FileStream {
    protected storage: Storage;
    protected file: File;
    protected readonly readAllowed: boolean;
    protected readonly writeAllowed: boolean;
    protected readonly appendMode: boolean;
    constructor(storage: Storage, file: File, mode: TextFileMode);
    /**
     * @param byteCount (defaults to all).
     * @returns The data read or `undefined` when the end is reached.
     *          Otherwise it's `false` and the error message on failure.
     */
    read(byteCount?: number): string | LuaMultiReturn<[boolean, string]> | undefined;
    /**
     * @return `true` on success. Otherwise it's `false` and the error message on failure.
     */
    write(...values: (string | number)[]): true | LuaMultiReturn<[boolean, string]>;
    /**
     * Sets and gets the file position, measured from the beginning of the file,
     * to the position given by offset plus a base specified by the string whence, as follows:
     *
     * - `set`: base is position 0 (beginning of the file).
     * - `cur`: base is current position.
     * - `end`: base is end of file.
     *
     * @return Position (relative to the start) after seeking.
     *         Otherwise it's `false` and the error message on failure.
     */
    seek(whence?: 'set' | 'cur' | 'end', offset?: number): number | LuaMultiReturn<[boolean, string]>;
    /**
     * Sets the buffering mode for an output file. There are three available modes:
     *
     * - `no`: no buffering; the result of any output operation appears immediately.
     * - `full`: full buffering; output operation is performed only when the buffer is full
     * (or when you explicitly flush the file (see io.flush)).
     * - `line`: line buffering; output is buffered until a newline is output or there is any input
     * from some special files (such as a terminal device).
     *
     * For the last two cases, size specifies the size of the buffer, in bytes. The default is an appropriate size.
     *
     * @returns `true` on success. Otherwise it's `false` and the error message on failure.
     */
    setvbuff(mode: 'no' | 'full' | 'line', size?: number): LuaMultiReturn<[success: true]> | LuaMultiReturn<[success: false, errormsg: string]>;
    /**
     * Flushes any buffered written data in the file to the disk.
     * @returns `true` on success. Otherwise it's `false` and the error message on failure.
     */
    flush(): LuaMultiReturn<[success: true]> | LuaMultiReturn<[success: false, errormsg: string]>;
    /**
     * Note that files are automatically closed when their handles are garbage collected,
     * but that takes an unpredictable amount of time to happen.
     * @return Always `true` (doesn't fail, _hopefully_).
     */
    close(): boolean;
}
//# sourceMappingURL=file-stream.d.ts.map