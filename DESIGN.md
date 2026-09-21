# mojo-flatbuffers design

This file records the decisions that the implementation follows. The site page
[Techniques](docs/techniques.md) explains the same mechanisms for readers of
the docs.

## Goal

A Mojo library that reads and writes FlatBuffers tables and FlexBuffers values.
Generated code offers a builder, a zero-copy view, and an owned unpack. Schemas
enter as `.fbs` text or as a `.bfbs` binary schema from `flatc`.

The runtime does not link a C, C++, or Rust FlatBuffers library. `flatc` and
Python `flatbuffers` are oracles. The library does not depend on the serializer
benchmark repository. The v2 `.fbs` file is copied into `testdata/`.

## Layers

| Layer | Path | Job |
| --- | --- | --- |
| Wire | `src/wire` | Backward builder, table reader, verifier |
| FlexBuffers | `src/flex` | Forward builder and owned reader |
| Schema | `src/schema` | `.fbs` parser, `.bfbs` decoder, shared model |
| Codegen | `src/codegen` | Emit Mojo from that model |
| Facade | `src/flatbuffers` | Re-exports for the published package |

## Key decisions

1. **Tables and FlexBuffers.** FlexBuffers is a separate codec in `src/flex`. It is not encoded as a FlatBuffers table.
2. **Three APIs for a table.** `pack` writes. A view borrows the buffer. `unpack` copies into Mojo values. The view is the fast read. The copy is what remains after the buffer is dropped.
3. **Both schema front ends.** The text parser and the `.bfbs` decoder fill one `Schema` model. The emitter sorts objects by name and fields by id so both inputs print the same Mojo.
4. **Core feature set.** Scalars, strings, vectors, tables, structs, enums, unions, defaults, optional scalars, file identifiers, size prefixes, and a verifier. Out of scope: 64-bit offsets, nested buffers, sorted-key vectors, and gRPC.
5. **Backward builder with a reused block.** Offsets stay positive. `clear` keeps the allocation. Vtables are deduplicated by a linear scan. String sharing is off unless requested.
6. **Generated code is straight-line.** The hot path does not walk a schema. That is the same split flatcc uses.
7. **Mojo 1.0 only.** Public functions are `def`. A negative soffset is sign-extended from a named `Int32`, because `Int(read_i32(...))` in one expression can zero-extend.
8. **License and package.** MIT, copyright Leonid Ganeline. Conda package `mojo-flatbuffers`. Module `flatbuffers`. Mojo pin `1.0.0`.

## Interop

A buffer produced for `features.Holder` is readable by `flatc --json`. A buffer
`flatc --binary` produces for the same schema is readable by `decode_Holder`,
including a union, an inline struct, and an optional scalar whose value is
zero. The builder tests also match the Python builder byte for byte on the
small buffers in `tests/test_builder.mojo`.
