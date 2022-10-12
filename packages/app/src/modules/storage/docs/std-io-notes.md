
# Notes after observing the standard Lua IO

After observing the standard Lua IO file streams under WSL2 system running Ubuntu.

The following notes has been found about allowed actions for different file modes.

## Error messages

- When reading or writing is not allowed due to the file mode, the message would be `Bad file descriptor`.
- When seeking on a standard io stream (`io.stdin`, `io.stdout`, ...), the message would be `Illegal seek`.
- When reading after reaching the stream end the operation fails with no error message (nil).
- When reading non-existing file, the message would be `{filename}: No such file or directory`.
- When writing a new file to a non-existing directory, the message would be `{filename}: No such file or directory`.
- When creating a file with illegal characters on windows, the message would be `Illegal characters in path`.

## Allowed operations

> It has been presumed that binary mode (with `b`) behaves the same.

| mode | initial seek |  seek   |   read    |  write  | existing data | notes                                                  |
|:-----|:------------:|:-------:|:---------:|:-------:|:-------------:|--------------------------------------------------------|
| `r`  |    start     | allowed |  allowed  |  error  |   persisted   |                                                        |
| `r+` |    start     | allowed |  allowed  | allowed |   persisted   | the ultimate mode                                      |
| `w`  |    start     | allowed |   error   | allowed |     lost      |                                                        |
| `w+` |    start     | allowed |  allowed  | allowed |     lost      |                                                        |
| `a`  |     end      | allowed |   error   | allowed |   persisted   | auto-seeks to the end before doing any write operation |
| `a+` |    start     | allowed |  allowed  | allowed |   persisted   | auto-seeks to the end before doing any write operation |

