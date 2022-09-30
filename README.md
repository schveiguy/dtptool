# Test out DrawTexturePro

raylib's DrawTexturePro function is quite complex, and the parameters affect the result in seemingly strange ways. This tool allows you to play with the various parameter values, to see how it will affect the result.

It includes an outline of where the source rectangle is in relation to the original texture, and also an outline in the target to show how the destination rectangle is used. It also allows you to play with the `origin` field, which is probably the least intuitive of the bunch!

To use, create a `testTexture.png` file in the project directory and run with dub.

There is a rudimentary gui here, the start of which I'll probably eventually build into something useful.

## Building

Please install the appropriate raylib library in the local directory. For macos and Windows, this can be accomplished by doing:

```sh
> dub run raylib-d:install
```

Once it is installed, run `dub` to build and run the application. It should work on MacOS and Windows, Linux may require some tinkering.
