/** @noSelfInFile */
import Machine from "core/machine";
import MachineModule from "core/machine-module";
import FileStream from "./file-stream";
export interface StorageOptions {
    capacity: number;
    basePath: string;
}
export declare type TextFileMode = 'r' | 'w' | 'a' | 'r+' | 'w+' | 'a+';
export declare type BinaryFileMode = 'rb' | 'wb' | 'ab' | 'rb+' | 'wb+' | 'ab+';
export declare type FileMode = TextFileMode | BinaryFileMode;
export interface FileInfo {
    type: 'file' | 'directory' | 'other';
    /**
     * The size in bytes of the file, or `undefined` if it can't be determined.
     */
    size?: number;
    /**
     * The file's last modification time in seconds since the unix epoch, or `undefined` if it can't be determined.
     */
    modtime?: number;
}
export default class Storage extends MachineModule {
    readonly totalSpace: number;
    usedSpace: number;
    protected basePath: string;
    constructor(machine: Machine, options: StorageOptions);
    createAPI(): {
        /**
         * @returns Total space in bytes.
         */
        getTotalSpace: () => number;
        /**
         * @returns Used space in bytes.
         */
        getUsedSpace: () => number;
        /**
         * @returns Available space in bytes.
         */
        getAvailableSpace: () => number;
        /**
         * @returns the file stream on success, otherwise false and the error message on failure.
         */
        open: (path: string, mode?: FileMode) => LuaMultiReturn<[boolean, string]> | FileStream;
        getInfo: (path: string) => import("love.filesystem").FileInfo<import("love.filesystem").FileType> | LuaMultiReturn<[boolean, string]>;
        delete: (path: string) => true | LuaMultiReturn<[boolean, string]>;
        createDirectory: (path: string) => true | LuaMultiReturn<[boolean, string]>;
        deleteDirectory: (path: string) => true | LuaMultiReturn<[boolean, string]>;
        readDirectory: (path: string) => string[] | LuaMultiReturn<[boolean, string]>;
    };
    protected refreshSpaceUsage(): void;
    protected createBasePathIfNotExists(): void;
}
//# sourceMappingURL=index.d.ts.map