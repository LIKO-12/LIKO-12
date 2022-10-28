
# Standard Lua Libraries Coverage

| Symbol | Legend                                                   |
|-------:|:---------------------------------------------------------|
|     🟢 | Using standard implementation.                           |
|     🟣 | Some methods patched by sandbox encapsulation.           |
|     🔵 | Some methods polyfilled by kernel.                       |
|     🟡 | Some methods are dummies that do nothing.                |
|     🟠 | Missing methods.                                         |
|     🔴 | Not implemented yet.                                     |
|      ❌ | Can't be implemented.                                    |
|     👌 | Conforms with standard documentation with full coverage. |

|     Library | Status | Notes                                                                                                                                  |
|------------:|--------|----------------------------------------------------------------------------------------------------------------------------------------|
| `coroutine` | 👌🟢🟣 |                                                                                                                                        |
|     `debug` | 🔴     |                                                                                                                                        |
|        `io` | 🔴     | missing `close`, `flush`, `input`, `lines`, `open`, `output`, `ropen`, `read`, `stderr`, `stdin`, `stdout`, `tmpfile`, `type`, `write` |
|      `math` | 👌🟢   |                                                                                                                                        |
|    `module` | 🔴     |                                                                                                                                        |
|   `package` | 🔴     |                                                                                                                                        |
|        `os` | 🟢🟠   | missing `execute`, `rename`, `tmpname`, `getenv`, `exit`, `remove`, `setlocale`                                                        |
|    `string` | 👌🟢   |                                                                                                                                        |
|     `table` | 👌🟢   |                                                                                                                                        |
|    `global` | 🟢🟠   | missing `require`, `loadfile`, `dofile`, `gcinfo`, `collectgarbage`, `newproxy`                                                        |
|       `jit` | 🔴     |                                                                                                                                        |
|       `ffi` | ❌🔴    | impossible to implement                                                                                                                |
|       `bit` | 👌🟢   |                                                                                                                                        |
