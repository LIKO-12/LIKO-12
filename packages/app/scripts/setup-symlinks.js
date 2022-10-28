/** @ts-check */
const fs = require('fs');
const path = require('path');

console.log('Script directory:', __dirname);

/**
 * @param {fs.PathLike} source 
 * @param {fs.PathLike} target 
 */
function link(source, target) {
    source = path.resolve(__dirname, source);
    target = path.resolve(__dirname, target);

    fs.mkdirSync(path.basename(target), { recursive: true });

    if (fs.existsSync(target)) {
        if (!fs.lstatSync(target).isSymbolicLink())
            fs.rmSync(target, { recursive: true });
        else if (path.resolve(fs.readlinkSync(target)) !== source)
            fs.unlinkSync(target);
    }
    
    if (!fs.existsSync(target)) {
        fs.symlinkSync(source, target, 'junction');
        console.info(`Created symlink '${source}' => '${target}' successfully ✔️`);
    }
}

link('../../kernel/out', '../res/kernel');
link('../res', '../out/res');

