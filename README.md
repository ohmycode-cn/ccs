# Convenient Compilation Scripts

A tiny collection of shell helpers for compiling and running code from a pure
terminal workflow — no IDE, no build system, just type one short command.

Designed for people who live in the shell (Termux, Linux, WSL, macOS) and want
to go from a source file to a running binary in a single keystroke-friendly
command.

## Why

When you are in a terminal-only session, the usual loop is:

```sh
clang -std=c23 foo.c -o foo && ./foo
```

which gets tedious fast. These scripts collapse that into one short call and
keep the output artifacts in a predictable `bin/` directory so your working
tree stays clean.

## Requirements

- `bash`
- `clang` (with C23 support) for the C helper

On Termux:

```sh
pkg install clang
```

## Usage

### `bash/runc.sh` — compile & run a C file

```sh
./bash/runc.sh path/to/foo.c
```

This compiles `foo.c` with `clang -std=c23`, drops the executable at
`bin/pubbin`, and immediately runs it. If compilation fails, you get a clear
error and nothing is executed.

You can also source it to get the `runc` function in your current shell:

```sh
source bash/runc.sh
runc foo.c
```

## Repository layout

```
.
├── bash/           # shell helpers
│   └── runc.sh     # compile + run a C source file
├── bin/            # build output (gitignored except .gitkeep)
└── README.md
```

## Conventions

- All helpers are plain POSIX-ish bash, no external frameworks.
- Scripts are safe to `source`: they detect sourcing vs. execution and only
  run `main` when executed directly.
- Build artifacts land in `bin/` and are ignored by git.

## License

MIT — do whatever you want, attribution appreciated.
