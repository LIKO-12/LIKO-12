import 'tests/storage.test';

// import 'modules/io';
// import 'modules/io.test';

function pullEvents(): LuaIterable<LuaMultiReturn<[string, ...any]>> {
    const { events } = liko;
    if (!events) throw 'events module is not loaded!';

    return (() => events.pull()) as any;
}

for (const [event, a, b, c, d, e, f] of pullEvents()) {
    print(event, a, b, c, d, e, f);
}

