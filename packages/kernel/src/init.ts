import 'modules/io';

const [file, message] = io.open('hello.txt', 'w');
if (file === undefined) throw message;

print(file);
print('read', file.read());
print('write', file.write('Hello from LIKO-12 and TypeScript!\r\n'));
print('write', file.write('Hello from LIKO-12 and TypeScript! (line 2)\r\n'));
print('write', file.write('Hello from LIKO-12 and TypeScript! (line 3)\r\n'));
print('flush', file.flush());
print('close', file.close());

const [file2, message2] = io.open('hello.txt');
if (file2 === undefined) throw message2;

print(file2);
print('read', file2.read('*l'));
print('read', file2.read('*a'));
print('read', file2.read(5));
print('close', file2.close());
print(file2);

const storage = liko.storage;
if (!storage) throw 'NO STORAGE MODULE';

const [file3, message3] = storage.open('hello.txt', 'w');
if (typeof file3 === 'boolean') throw message3;

print(file3);
const [ok, msg] = file3.read();
print('read', ok, msg);
file3.close();

function pullEvents(): LuaIterable<LuaMultiReturn<[string, ...any]>> {
    const { events } = liko;
    if (!events) throw 'events module is not loaded!';

    return (() => events.pull()) as any;
}

for (const [event, a, b, c, d, e, f] of pullEvents()) {
    print(event, a, b, c, d, e, f);
}

