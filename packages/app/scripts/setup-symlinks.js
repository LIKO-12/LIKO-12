/** @ts-check */
const fs = require('fs');
const path = require('path');

const source = path.resolve(__dirname, '../res');
const target = path.resolve(__dirname, '../out/res');

fs.mkdirSync(path.basename(target), { recursive: true });

if (fs.existsSync(target)) {
    if (!fs.lstatSync(target).isSymbolicLink())
        fs.rmSync(target, { recursive: true });
    else if (path.resolve(fs.readlinkSync(target)) !== source)
        fs.unlinkSync(target);
}

if (!fs.existsSync(target)) {
    fs.symlinkSync(source, target, 'junction');
    console.info('Created symlink successfully ✔️');
}