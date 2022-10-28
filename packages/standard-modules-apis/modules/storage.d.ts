declare namespace StandardModules {
    export namespace Storage {
        type TextFileMode = 'r' | 'w' | 'a' | 'r+' | 'w+' | 'a+';
        type BinaryFileMode = 'rb' | 'wb' | 'ab' | 'rb+' | 'wb+' | 'ab+';
        export type FileMode = TextFileMode | BinaryFileMode;

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

        export interface FileStream {
            /**
             * @param byteCount (defaults to all).
             * @returns The data read or `undefined` when the end is reached.
             *          Otherwise it's `false` and the error message on failure.
             */
            read(this: FileStream, byteCount?: number): string | LuaMultiReturn<[boolean, string]> | undefined;

            /**
             * @return `true` on success. Otherwise it's `false` and the error message on failure.
             */
            write(this: FileStream, ...values: (string | number)[]): true | LuaMultiReturn<[boolean, string]>;

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
             *         Otherwise it's `false` and the error message on failure.
             */
            seek(this: FileStream, whence: 'set' | 'cur' | 'end', offset: number): number | LuaMultiReturn<[boolean, string]>;

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
            setvbuff(this: FileStream, mode: 'no' | 'full' | 'line', size?: number): LuaMultiReturn<[success: true]> | LuaMultiReturn<[success: false, message: string]>;

            /**
             * Flushes any buffered written data in the file to the disk.
             * @returns `true` on success. Otherwise it's `false` and the error message on failure.
             */
            flush(this: FileStream): LuaMultiReturn<[success: true]> | LuaMultiReturn<[success: false, message: string]>;

            /**
             * Note that files are automatically closed when their handles are garbage collected,
             * but that takes an unpredictable amount of time to happen.
             * @return Always `true` (doesn't fail, _hopefully_).
             */
            close(this: FileStream): boolean;
        }
    }


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
         * @returns the file stream on success, otherwise false and the error message on failure.
         */
        open(this: void, path: string, mode: Storage.FileMode): Storage.FileStream | LuaMultiReturn<[boolean, string]>;

        getInfo(this: void, path: string): Storage.FileInfo | LuaMultiReturn<[boolean, string]>;

        delete(this: void, path: string): true | LuaMultiReturn<[boolean, string]>;

        createDirectory(this: void, path: string): true | LuaMultiReturn<[boolean, string]>;

        deleteDirectory(this: void, path: string): true | LuaMultiReturn<[boolean, string]>;

        readDirectory(this: void, path: string): string[] | LuaMultiReturn<[boolean, string]>;
    }
}