import { validateParameters } from 'core/utilities';
import { BufferMode, File } from 'love.filesystem';
import Storage, { TextFileMode } from '.';

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
    protected readonly readAllowed: boolean;
    protected readonly writeAllowed: boolean;
    protected readonly appendMode: boolean;

    constructor(
        protected storage: Storage,
        protected file: File,
        mode: TextFileMode
    ) {
        // Check `modules/storage/docs/std-io-notes.md` for how those were determined. (allowed operations section).

        this.readAllowed = (mode !== 'w' && mode !== 'a');
        this.writeAllowed = (mode !== 'r');
        this.appendMode = (mode === 'a' || mode === 'a+');
    }

    /**
     * @param byteCount (defaults to all).
     * @returns The data read or `undefined` when the end is reached.
     *          Otherwise it's `false` and the error message on failure.
     */
    read(byteCount?: number) {
        validateParameters();

        try {
            const [content] = this.file.read(byteCount);
            return content;
        } catch (message: unknown) {
            if (message === undefined) return undefined;
            else return $multi(false, tostring(message));
        }
    }

    /**
     * @return `true` on success. Otherwise it's `false` and the error message on failure.
     */
    write(...values: (string | number)[]) {
        validateParameters();

        if (!this.writeAllowed) return $multi(false, 'Bad file descriptor');
        if (this.appendMode) this.file.seek(this.file.getSize());

        let availableStorage = this.storage.totalSpace - this.storage.usedSpace;
        let overridableLength = this.file.getSize() - this.file.tell();

        for (let position = 0; position < values.length; position++) {
            const value = tostring(values[position]);
            let length = value.length;

            if (length > availableStorage + overridableLength)
                return $multi(false, 'out of storage space');

            if (overridableLength === 0)
                availableStorage -= length;
            else {
                const consumed = Math.min(overridableLength, length);
                overridableLength -= consumed;
                length -= consumed;
            }

            this.storage.usedSpace += length;

            try {
                assert(this.file.write(value));
            } catch (message: unknown) {
                return $multi(false, tostring(message));
            }
        }

        return true;
    }

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
    seek(whence: 'set' | 'cur' | 'end' = 'cur', offset = 0) {
        validateParameters();

        if (whence === 'cur')
            offset += this.file.tell();
        else if (whence === 'end')
            offset += this.file.getSize();
        else if (whence !== 'set')
            error(`bad argument #1 to 'seek' (invalid option '${whence}')`, 2);

        // out of bounds seeks cause the seek to fail without error message.
        if (offset < 0) offset = 0;
        if (offset > this.file.getSize()) offset = this.file.getSize();

        try {
            assert(this.file.seek(offset));
            return this.file.tell();
        } catch (message: unknown) {
            return $multi(false, tostring(message));
        }
    }

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
    setvbuff(mode: 'no' | 'full' | 'line', size?: number) {
        validateParameters();

        if (mode !== 'no' && mode !== 'full' && mode !== 'line')
            error(`bad argument #1 to 'setvbuf' (invalid option '${mode}')`, 2);

        let loveMode: BufferMode = mode === 'no' ? 'none' : mode;
        return this.file.setBuffer(loveMode, size);
    }

    /**
     * Flushes any buffered written data in the file to the disk.
     * @returns `true` on success. Otherwise it's `false` and the error message on failure.
     */
    flush() {
        return this.file.flush();
    }

    /**
     * Note that files are automatically closed when their handles are garbage collected,
     * but that takes an unpredictable amount of time to happen.
     * @return Always `true` (doesn't fail, _hopefully_).
     */
    close() {
        return this.file.close();
    }
}