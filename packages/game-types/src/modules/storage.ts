export type FileMode = 'r' | 'w' | 'a' | 'r+' | 'w+' | 'a+';

export type FileInfo = {
    /**
     * The file type of the object at the path.
     */
    type: "file" | "directory" | "symlink" | "other";

    /**
     * The size in bytes of the file.
     */
    size?: number;

    /**
     * The file's last modification time in seconds since the unix epoch.
     */
    modtime?: number;
};

/**
 * The methods provided by this API can fail and throw errors.
 */
export interface FileStream {
    /**
     * @param byteCount (defaults to all).
     * @returns The data read or `undefined` when the end is reached.
     */
    read(this: FileStream, byteCount?: number): string | undefined;

    /**
     * @return the file itself. (allows chained methods calls).
     */
    write(this: FileStream, ...values: (string | number)[]): FileStream;

    /**
     * Sets and gets the file position, measured from the beginning of the file,
     * to the position given by offset plus a base specified by the string whence, as follows:
     * 
     * - `set`: base is position 0 (beginning of the file).
     * - `cur`: base is current position.
     * - `end`: base is end of file.
     * 
     * @param whence defaults to `'cur'`.
     * @param offset defaults to `0`.
     * @return Position (relative to the start) after seeking.
     */
    seek(this: FileStream, whence?: 'set' | 'cur' | 'end', offset?: number): number;

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
     */
    setvbuff(this: FileStream, mode: 'no' | 'full' | 'line', size?: number): void;

    /**
     * Flushes any buffered written data in the file to the disk.
     */
    flush(this: FileStream): void;

    /**
     * Note that files are automatically closed when their handles are garbage collected,
     * but that takes an unpredictable amount of time to happen.
     */
    close(this: FileStream): void;
}


/**
 * The methods provided by this API can fail and throw errors.
 */
export interface StorageAPI {
    /**
     * @returns Total space in bytes.
     */
    getTotalSpace(this: void): number;

    /**
     * @returns Used space in bytes.
     */
    getUsedSpace(this: void): number;

    /**
     * @returns Available space in bytes.
     */
    getAvailableSpace(this: void): number;

    /**
     * @param mode defaults to `'r'`.
     */
    open(this: void, path: string, mode?: FileMode): FileStream;

    getInfo(this: void, path: string): FileInfo;

    removeFile(this: void, path: string): void;

    /**
     * Creates a directory and any parent directories needed.
     */
    createDirectory(this: void, path: string): void;

    removeDirectory(this: void, path: string): void;

    readDirectory(this: void, path: string): string[];
}