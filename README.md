# nix-python-uv

## What's here

This is a fully-fledged python project controlled by the `uv` package manager.
Firstly there's the main library defined in the `pyproject.yaml` and in the
`nix_python_uv` folder. There's some scripts, tests, and a few examples of
dependencies.

In the Nix setup we define some the build environment, tests, code formatters,
and a docker image with the entrypoint ready to run.


## What's possible

#### Regular Python development

``` sh
python
...
>>> import pandas
```

#### Running an entrypoint with `nix run ...`

``` sh
nix run .
```

#### Running a `[script]` entrypoint directly

``` sh
> hello
Hello, world!

> some_script
Hello, world!
Hello, other world!
```


#### Building a Docker image

``` sh
nix build .#docker-image
./result < docker load
docker run nix-python-uv-hello
```


#### Testing

You can run the tests with pytest:

``` sh
pytest
```

Or, with `nix flake check`

``` sh
nix flake check
```

> [!Note]
>
> Running tests like this with Nix is a bit subtle; if the tests are simple;
> i.e. "pure"; that is, they don't require external dependencies, then they
> will work.


#### Code formatting

``` sh
nix fmt
```

> [!Note]
>
> `nix fmt` only formats files that are changed; not all files in the
> repo. For that, run `ruff format` directly.


#### Add a new dependency

``` sh
uv add numpy
```


## Tips and trivia

- Each time you add a new dependency you need to reload the devShell. I have a
  shell alias, `alias rr="direnv reload"` for this purpose.


## How to use/extend this

For the most part, if you simply make changes with `uv` this should "Just
Work". There will be some busywork if some of the Python dependencies aren't
perfectly configured; but all of that can be addressed.

To add a new package, just add it next to `pkgs.uv` in
[nix/outputs.nix](./nix/outputs.nix) in the `devShells` `package` statement.
