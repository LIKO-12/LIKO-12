
# Contribution Guide

## Building LIKO-12

### Packing a universal `.love` file

Simply pack the content of the `src` folder (without the wrapping folder) into a `.zip` file and rename it's extension to `.love`.

### Creating platform-specific binaries

Follow the instructions on [LÖVE Wiki](https://love2d.org/wiki/Game_Distribution).

## Setting up development environment

1. Install [LÖVE](https://love2d.org/wiki/Getting_Started) 11.4.
2. If you are on Windows add the `love` executable to path.
3. Clone the project locally.
4. Open the project with your favorite IDE that supports Lua highlighting.
5. To run LIKO-12 type `love ./src` in the terminal (with the repository root being the working directory).

### Visual Studio Code

- Find some Lua extension (right now I don't know what reliable ones are there).
- `tasks.json` is provided to simply run LIKO-12 with the right arguments.

## Linting

Using the [lunarmodules fork of luacheck](https://github.com/lunarmodules/luacheck).
