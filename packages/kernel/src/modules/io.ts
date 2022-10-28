class File implements LuaFile {
    constructor(private fileStream: StandardModules.Storage.FileStream) { }

    seek(whence?: 'set' | 'cur' | 'end' | undefined, offset?: number | undefined): LuaMultiReturn<[undefined, string] | [number]> {
        return this.fileStream.seek(whence, offset);

    }

    setvbuf(mode: 'no' | 'full' | 'line', size?: number | undefined): void {
        const [success, message] = this.fileStream.setvbuff(mode, size);
        assert(success, message);
    }


    lines<T extends io.FileReadFormat[]>(...formats: T): LuaIterable<LuaMultiReturn<[] extends T ? [string] : { [P in keyof T]: io.FileReadFormatToType<T[P]>; }>, undefined> {
        formats.reverse();

        const iterator: any =  () => {
            const format = formats.pop();
            return format === undefined ? undefined : this.read(format);
        };

        return iterator;
    }

    read(): io.FileReadFormatToType<io.FileReadLineFormat> | undefined;
    read<T extends io.FileReadFormat>(format: T): io.FileReadFormatToType<T> | undefined;
    read<T extends io.FileReadFormat[]>(...formats: T): LuaMultiReturn<{ [P in keyof T]?: io.FileReadFormatToType<T[P]> | undefined; }>;
    read(...formats: io.FileReadFormat[]): string | number | undefined | LuaMultiReturn<(string | number | undefined)[]> {
        const results: (string | number | undefined)[] = [];
        let parameterPosition = 0;

        for (const format of formats) {
            parameterPosition++;

            if (typeof format === 'number' || format === '*a') {
                const [success] = this.fileStream.read(format === '*a' ? undefined : format);
                results.push(typeof success === 'string' ? success : undefined);

            } else if (format === '*n') {
                throw new Error('*n is unsupported.'); // FIXME: Unimplemented.

            } else if (format === '*l' || format === '*L') {
                const buffer: string[] = [];

                while (true) {
                    const [char] = this.fileStream.read(1);
                    if (!char) break;

                    if (char !== '\n' || format === '*L') buffer.push(char);
                    if (char === '\n') break;
                }

                if (format === '*l' && buffer[buffer.length - 1] === '\r') buffer.pop();
                results.push(buffer.join(''));

            } else {
                error(`bad argument #${parameterPosition} to 'read' (invalid format)`, 2)
            }
        }

        return $multi(...results);
    }

    write(...args: (string | number)[]): LuaMultiReturn<[LuaFile] | [undefined, string]> {
        const [success, message] = this.fileStream.write(...args);

        if (success) return $multi(this);
        else return $multi(undefined, message);
    }

    flush(): boolean {
        const [success] = this.fileStream.flush();
        return success;
    }

    close(): boolean {
        return this.fileStream.close();
    }

    __tostring(): string {
        return `file (${string.sub(tostring(this), 8, -1)})`;
    }
}

(() => {
    const storage = liko.storage;
    if (storage === undefined) return;

    const virtualIO: Partial<typeof io> = {
        open: (filename, mode) => {
            const [fileSteam, message] = storage.open(filename, mode as StandardModules.Storage.FileMode | undefined);
            if (typeof fileSteam === 'boolean') return $multi(undefined, tostring(message), 1);

            return $multi(new File(fileSteam));
        }
    };

    (_G['io'] as any) = virtualIO;
})();
