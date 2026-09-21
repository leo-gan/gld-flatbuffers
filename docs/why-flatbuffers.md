# Why FlatBuffers

[FlatBuffers](https://flatbuffers.dev/) is a binary format from Google. A
program describes its records in a `.fbs` schema. A code generator then writes
a builder and a reader for that schema. The bytes do not carry field names.
The schema does.

The same project defines [FlexBuffers](https://flatbuffers.dev/flexbuffers.html).
FlexBuffers is a different format. Each value carries its own type, so a
decoder does not need a `.fbs` file. This library implements both.

This library is written in Mojo. It does not call the C++ FlatBuffers runtime.
`flatc` and Python `flatbuffers` are used to check bytes. They are not linked
into the codec.

[Instructions](instructions.md) shows how to install and generate code.
[Examples](examples.md) shows the matching Mojo calls.
[Techniques](techniques.md) explains how the builder is arranged.

## Tables

A **table** is the usual FlatBuffers record. Fields may be added later. Old
readers skip the ones they do not know, because each table points at a
**vtable**. The vtable is a list of byte offsets. A zero offset means the
field is absent.

Absent scalars return the schema default. A scalar written as `= null` in the
schema is optional: absence is `None`, and zero is a real value. Strings,
vectors, nested tables, and inline structs are absent until the builder stores
them.

The buffer is little-endian. A `uoffset` is a 32-bit distance stored at the
field and added to the field's own address. Children sit at higher addresses
than the parent, because the builder writes from the end of the buffer toward
the start.

## Structs, enums, and unions

A **struct** has a fixed layout. Every field is present, and there is no
vtable. Structs are stored inline in the parent.

An **enum** is an integer with named values. A **union** is two slots: a type
byte, then an offset to one table. Type `0` means none.

A **vector** is a 32-bit length followed by elements. Scalar elements are
packed. Table and string elements are offsets. Struct elements are inline.

The first four bytes of a finished buffer are the root offset. An optional
file identifier is the next four bytes. A size prefix, when requested, is a
32-bit length before the root offset. The length counts the bytes that follow
it.

## What this library implements

| In this library | Not in this library |
| --- | --- |
| Tables, structs, enums, unions | 64-bit offsets |
| Scalars, strings, vectors | Nested buffers |
| Defaults and optional scalars | Sorted-key vectors |
| File identifier and size prefix | gRPC services |
| A bounds-checking verifier | A reflection reader for arbitrary buffers |
| `.fbs` text and `.bfbs` binary schemas | |
| FlexBuffers values, vectors, and maps | |

Generated code has three ways to use a table. `pack` writes bytes. A view
reads fields from the buffer and does not copy strings until you ask. `unpack`
copies into owned Mojo values. The view is the fast read. The owned value is
what you keep after the buffer is gone.

## FlexBuffers

A FlexBuffers buffer ends with two bytes: the root type, then the width of the
root value (1, 2, 4, or 8). Integers and floats that fit in a smaller width
use that width. Strings and maps store an offset back into the buffer.

Maps keep their keys in sorted order. A reader can binary-search them. This
library's `flex_loads` copies the value into an owned tree, because there is
no schema to hang a typed view on.
