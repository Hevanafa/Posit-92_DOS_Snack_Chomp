## Directories for release

- `dos` contains the DOSBox config used by js-dos v7
- `web` contains the entry point or "site" (`game.zip` is added to .gitignore)

## game.zip structure

This ZIP file (`game.zip`) is required by the entry point `web/index.html`

There are 2 important items inside the ZIP:

- `.jsdos/`
- `(game files)`

`.jsdos` is exactly the copy from the `dos` directory

`(game files)` are obviously your game EXE and all of your game assets

## js-dos v7 guide

Obtained from this command line:

```powershell
npx create-dosbox my-app
```

Follow the default prompt

Then, after downloading, see the `_site` directory, there is a folder named `js-dos`, which is the vendored emulator runtime

The other files that you can use are:
- `bundle.jsdos`, which you can rename to `game.zip` later
- `index.html`: the entry point
