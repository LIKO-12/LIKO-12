import { validateParameters } from "core/utilities";
import { BufferMode, File } from "love.filesystem";
import Storage, { FileMode } from ".";

/**
 * File object for reading and writing into a file.
 * 
 * Close to standard Lua `io` files in functionality.
 * With deference mainly in:
 *  - files are always in binary `b` mode.
 *  - `file:read` only accepts bytes count.
 *  - `file:lines` is not implemented.
 *  - possibly some difference in error messages.
 */
export default class FileStream implements Storage.FileStream {
    protected readonly readAllowed: boolean;
    protected readonly writeAllowed: boolean;
    protected readonly appendMode: boolean;

    constructor(
        protected storage: Storage,
        protected file: File,
        mode: FileMode
    ) {
        // Check `modules/storage/docs/std-io-notes.md` for how those were determined. (allowed operations section).

        this.readAllowed = (mode !== 'w' && mode !== 'a');
        this.writeAllowed = (mode !== 'r');
        this.appendMode = (mode === 'a' || mode === 'a+');
    }

    read(byteCount?: number) {
        validateParameters();

        if (!this.readAllowed) error('Bad file descriptor', 2);

        try {
            const [content] = this.file.read(byteCount);
            return content;
        } catch (message: unknown) {
            if (message === undefined) return undefined;
            else error(tostring(message), 2);
        }
    }

    write(...values: (string | number)[]) {
        validateParameters();

        if (!this.writeAllowed) error('Bad file descriptor', 2);
        if (this.appendMode) this.file.seek(this.file.getSize());

        let availableStorage = this.storage.totalSpace - this.storage.usedSpace;
        let overridableLength = this.file.getSize() - this.file.tell();

        for (let position = 0; position < values.length; position++) {
            const value = tostring(values[position]);
            let length = value.length;

            if (length > availableStorage + overridableLength)
                error('out of storage space', 2);
            
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
                error(tostring(message), 2);
            }
        }

        return this;
    }

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
        } catch(message: unknown) {
            error(tostring(message), 2);
        }
    }

    setvbuff(mode: 'no' | 'full' | 'line', size?: number) {
        validateParameters();

        if (mode !== 'no' && mode !== 'full' && mode !== 'line')
            error(`bad argument #1 to 'setvbuf' (invalid option '${mode}')`, 2);
        
        let loveMode: BufferMode = mode === 'no' ? 'none' : mode;
        try {
            assert(this.file.setBuffer(loveMode, size));
        } catch(message: unknown) {
            error(tostring(message), 2);
        }
    }

    flush() {
        try {
            assert(this.file.flush());
        } catch(message: unknown) {
            error(tostring(message), 2);
        }
    }

    close() {
        try {
            assert(this.file.close());
        } catch(message: unknown) {
            error(tostring(message), 2);
        }
    }
}