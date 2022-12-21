/**
 * A library to simplify the usage of the storage module.
 */

const storage = liko.storage!;
if (!storage) error("the liko 'storage' module is not loaded.");

export const getTotalSpace = storage.getTotalSpace;
export const getUsedSpace = storage.getUsedSpace;
export const getAvailableSpace = storage.getAvailableSpace;

export const open = storage.open;
export const getInfo = storage.getInfo;
export const removeFile = storage.removeFile;

export const createDirectory = storage.createDirectory;
export const removeDirectory = storage.removeDirectory;
export const readDirectory = storage.readDirectory;

export function readFileSync(path: string): string {
    const file = storage.open(path, 'r');
    const content = file.read();
    file.close();

    return content ?? '';
}

export function writeFileSync(path: string, data: string): void {
    const file = storage.open(path, 'w');
    file.write(data);
    file.close();
}

export function appendFileSync(path: string, data: string): void {
    const file = storage.open(path, 'a');
    file.write(data);
    file.close();
}
