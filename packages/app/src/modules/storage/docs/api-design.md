
# Storage API Design

The goal is to provide a filesystem I/O api which is:

- Can be used to reconstruct the standard Lua `io` library.
- Reconstruct important parts of the famous `lfs` (lua-filesystem) library.
- Compatible across platforms: Windows, Linux, macOS and Android.
- Can be virtually simulated (for example when running under a browser).
- Has a storage limit and can't access outside the appdata folder.
- Measure and work with bytes.
- Always use binary mode.

## Features

- Open file as stream.
  - read, write, append.
  - seek, buffered.
- Get info about a file.
  - type: `file`, `directory`, `other`.
  - size, last modified.
- Follow host system symlinks.
- Delete files.
- Get used, remaining and total space.
- Create, read (list content) and delete directories (non-recursively).
- Sanitizes the paths.
- Doesn't throw errors but instead returns false and the error message (like Lua `io`).
- Throws error for invalid parameters types.

## Sanitizing a path

- The result path should be **absolute** not _relative_ and in Unix style.
- In relative paths `.` and `..` should be resolved.
- Windows style paths are automatically converted into Unix style.
- Forbid disallowed filename characters.

## Disallowed filename characters

> ["What characters are forbidden in Windows and Linux directory names?"](https://stackoverflow.com/questions/1976007/what-characters-are-forbidden-in-windows-and-linux-directory-names)

- Forbid creating a directory or a file with name `.` or `..`.
- Forbid `<>:"/\|?*` characters.
- Forbid ASCII control characters (0-31) (non-printable characters).
