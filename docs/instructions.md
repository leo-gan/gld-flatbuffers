# Instructions

If you have not used FlatBuffers as a wire format before, start with
[Why FlatBuffers](why-flatbuffers.md). That page explains tables, vtables,
structs, unions, and FlexBuffers.
[Techniques](techniques.md) explains how the builder and the code generator
are implemented.

## Install Mojo 1.0.0

```bash
git clone https://github.com/leo-gan/gld-flatbuffers.git
cd gld-flatbuffers
pixi install
pixi run test
```

If `pixi install` fails with 401 on `conda.modular.com`, set `PREFIX_API_KEY`
in a local `.env` (never commit that file) and run `scripts/ci-setup.sh`.

After a conda install from prefix.dev:

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-flatbuffers
```

That installs `flatbuffers.mojoc` (plus `wire`, `flex`, and `schema`) and
`gld-flatc-mojo`. The package requires `mojo-compiler` 1.0.0. Those
`.mojoc` files are bytecode from that compiler, and Mojo 1.1.0 refuses to
load them.

## Generate Mojo from a schema

Write a `.fbs` file, or ask `flatc` for a binary schema:

```bash
flatc --binary --schema -o testdata/schema testdata/schema/features.fbs
```

Then run the generator. After a conda install the command is `gld-flatc-mojo`.
In a checkout:

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --fbs testdata/schema/features.fbs --out tests/generated
```

`--bfbs testdata/schema/features.bfbs` reads the binary schema instead. Both
front ends emit the same Mojo for the schemas in this repository.
`pixi run generate` rebuilds `tests/generated` from the `.fbs` files.

A scalar written as `= null` becomes `Optional[T]`. A nested table or a struct
field becomes a value plus a `has_` flag. An empty string or an empty vector
is omitted on write and comes back empty on read.

## Encode and decode

```mojo
from features import Holder, decode_Holder, encode_Holder, view_Holder

var h = Holder()
h.name = "kelp"
h.has_point = True
h.point.x = 1.5
var buf = encode_Holder(h)
var again = decode_Holder(buf)
var view = view_Holder(buf)
```

`from features import …` resolves when the generated file is on the Mojo
include path. `from flatbuffers import Builder` resolves with `mojo run -I src`
in a checkout, or from `flatbuffers.mojoc` after the package is installed.

The view reads `buf`. Keep `buf` alive while you use the view. `decode_Holder`
copies strings and lists out, so the copy does not depend on `buf`.

FlexBuffers does not use a schema:

```mojo
from flex.builder import FlexBuilder
from flex.reader import flex_loads

var b = FlexBuilder()
var start = b.start_map()
b.key("harbor")
b.string("kelp")
b.end_map(start)
var tree = flex_loads(b.finish())
```

## Tests and docs

```bash
pixi run test
pixi run precompile
mkdocs build --strict
mkdocs serve
```

`pixi run test` runs every `tests/test_*.mojo` file. The site in `docs/` is
published from the `Pages` workflow on `main`.
