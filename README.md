# mojo-flatbuffers

A from-scratch [FlatBuffers](https://flatbuffers.dev/) implementation for
[Mojo](https://www.modular.com/mojo). The runtime, the schema front ends, and
the code generator are written in Mojo. They do not wrap, link, or vendor the
C++ FlatBuffers library, flatcc, or any other C, C++, or Rust FlatBuffers
library.

`flatc` and the Python `flatbuffers` package are test oracles. A program that
only encodes and decodes does not need them. `flatc` is also one way to produce
a binary schema (`.bfbs`) for the code generator. The generator can parse `.fbs`
text itself.

This repository is a standalone library. It is not part of any other project.

Documentation: [leo-gan.github.io/gld-flatbuffers](https://leo-gan.github.io/gld-flatbuffers/).
That site explains tables and FlexBuffers, the install steps, examples, the
encode and decode techniques, and the test data.

## Install

Published package (linux-64) on [prefix.dev/leo-gan/leo-gan](https://prefix.dev/leo-gan/leo-gan):

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-flatbuffers
```

## Develop

```bash
git clone https://github.com/leo-gan/gld-flatbuffers.git
cd gld-flatbuffers
pixi install
pixi run test
```

If `pixi install` fails with 401 on `conda.modular.com`, set `PREFIX_API_KEY`
in a local `.env` (never commit that file) and run `scripts/ci-setup.sh`.

## License

MIT. Copyright (c) 2026 Leonid Ganeline.
