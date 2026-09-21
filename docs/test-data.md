# Test data

The files under `testdata/` are ordinary inputs for the tests. They are not a
product schema. The Mojo tests compare either these bytes or values decoded
from buffers the library just built.

`flatc` wrote the `.bfbs` files. The `.fbs` files are the source. Do not edit
a `.bfbs` by hand. Regenerate it with:

```bash
flatc --binary --schema -o testdata/schema testdata/schema/benchmark_v2.fbs
```

## Schemas

| File | What it is | Why it is here |
| --- | --- | --- |
| `testdata/schema/benchmark_v2.fbs` | The v2 record schema: `Message`, `Document`, `Telemetry`, `Strings`, `Event`, the batch tables, and `FixtureRoot`. | This is the shape the serializer benchmark uses. The library does not import that repository. The schema is copied so the tests can round-trip the same tables. |
| `testdata/schema/benchmark_v2.bfbs` | `flatc --binary --schema` output for that file. File identifier `BFBS`. | The binary-schema front end must see the same objects, field ids, and enum indexes as the text parser. |
| `testdata/schema/features.fbs` | `Color`, inline `Point` and `Mixed`, union `Item`, optional `maybe`, and vectors. Root `Holder`, file identifier `HOLD`. | Covers structs, unions, defaults, and optional scalars that the benchmark schema does not use. |
| `testdata/schema/features.bfbs` | Binary schema for `features.fbs`. | Same front-end check as the benchmark schema. |
| `testdata/schema/child.fbs` | `demo.child.Kid`. | Included by `parent.fbs`. |
| `testdata/schema/parent.fbs` | `include "child.fbs"` and a field of type `demo.child.Kid`. | Checks that include resolution qualifies names across files. |

`benchmark_v2.fbs` keeps the names from the benchmark schema, including the
enum `FixtureKind`. The docs call these files test data. The enum name is part
of the copied schema.

## Generated Mojo

`tests/generated/benchmark_v2.mojo` and `tests/generated/features.mojo` are
checked in so `pixi run test` does not need `flatc`. `pixi run generate`
rewrites them from the `.fbs` files. `scripts/check-generated.sh` also builds
the `.bfbs` path and diffs the text. `tests/test_codegen.mojo` does that diff
inside the Mojo test process.

## Bytes that are not files

The builder tests embed hex from the Python `flatbuffers.Builder` for one
integer field, two fields, a string, a vector of doubles, a file identifier,
a size prefix, an omitted default, and a shared vtable. The FlexBuffers tests
embed the compliance bytes: integers, `kelp`, a blob, `[1, 2, 3]`, an empty
vector, the map `harbor=kelp`, and the official gold example. Those hex
strings live in `tests/test_builder.mojo` and `tests/test_flex.mojo`.

A short buffer (`""`, `"0000"`, `"000000"`, and a four-byte stub that claims a
file identifier) is rejected by `verify_root` or `verify_file_identifier`.
Those cases are the table and file-identifier checks from the compliance
catalog. They do not need a schema.
