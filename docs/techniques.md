# Techniques

This page explains how mojo-flatbuffers encodes and decodes, why those choices
exist, and which ideas were not used. It describes the shipped code.

The library is written in Mojo. It does not call the C++ `FlatBufferBuilder`,
flatcc, or the Zig `zig-flatbuffers` runtime. The builder follows the same
byte rules as the Python `flatbuffers` builder, which matches `flatc` for the
schemas in this repository.

The speed target is a generated table: `pack` writes bytes, and a view reads
fields from those bytes. FlexBuffers is a second format. Its reader returns an
owned tree, because a FlexBuffers value names its own type and there is no
schema to specialize.

## What the other languages actually time

The serializer benchmark has a FlatBuffers row in several languages. Two of
the fastest dashboard rows do not build the suite schema. The C `flatcc` row
and the C++ `flatbuffers` row wrap another payload in a single vector. Their
times are a builder microbenchmark, not a `Document` round trip.

The rows that build the suite tables are different:

| Language | Library | What the timed path does |
| --- | --- | --- |
| Zig | zig-flatbuffers 0.2.1 | `Builder.writeTable`, then `decodeRoot` plus a copy into the suite value |
| Java | official FlatBuffers | One reused `FlatBufferBuilder`, then an unpack into objects |
| C# | FlatSharp | Generated serialize and parse |
| Swift, Kotlin, JavaScript, Python | official generators | Generated pack and unpack |

Zig is the fastest of those schema rows on the small `Document` and
`Telemetry` cells. Its read is a view, and the suite still pays for a copy
into the host value. That split is why this library has both a view and
`unpack`.

## The builder writes backward

`Builder` keeps one byte block. `head` starts at the end. Each `place` stores
the next value at a lower address. A `uoffset` is then a positive distance
from the field to a child that was written earlier.

The block doubles when `head` runs out of room. The live suffix is copied to
the end of the new block with one `memcpy`, so every offset measured from the
end stays valid. Padding bytes are written as zeros. `clear` sets `head` back
to the end and resets the scratch counts. It keeps the byte block and the
vtable lists. The next message overwrites the suffix it uses. Bytes below the
new `head` are not part of the output, so `clear` does not have to zero them.

`finish` copies the live suffix into a `List[Byte]` the caller owns, again
with one `memcpy`. Strings and byte vectors are copied the same way. Scalars
are stored and loaded as one little-endian machine word, which matches the
wire on x86-64. A scalar vector is reserved once by `start_vector`; each
element is then stored with `push_*` and does not recompute alignment. A
string read checks the length and the trailing NUL, then copies the bytes
with `String(unsafe_from_utf8=)` and does not scan them for UTF-8 again.
`TableRef` reads the vtable header once per table. Reusing the builder avoids
allocating the scratch block, the vtable list, or the string map on every
message. The string map is rebuilt only when string sharing is on.

Default fields are omitted. `add_i32` writes a field only when the value
differs from the schema default, unless `set_force_defaults` is on. That is
the same rule as `flatc`. Optional scalars (`= null` in the schema) are
written whenever they are set, including zero.

## Vtables are compared, not hashed

A vtable is two `uint16` sizes plus one `uint16` offset per field. Trailing
absent fields are trimmed. Before the vtable is written, the builder scans the
vtables already stored in this buffer and reuses one with the same offsets.

The scan is linear. A hash map of vtable keys would allocate on the hot path,
and a message has few distinct shapes. The C++ builder uses the same linear
compare. The Python builder hashes the key. The bytes match either way. The
test `test_vtable_dedup` checks the shared-vtable buffer against the Python
builder.

String deduplication is optional (`set_share_strings`). It is off by default.
The v2 records mostly use each string once, and a map lookup costs more than
it saves on that input. Turn it on when one buffer repeats the same text.

## Generated code does not interpret the schema

`gld-flatc-mojo` reads a schema and writes straight-line Mojo. `pack` calls
`create_string`, `start_vector`, and `add_i32` directly. The hot path does not
walk a field list. That is the flatcc idea: the generator does the schema work
once.

There are two front ends, and they produce one model.

| Front end | Input | What it does |
| --- | --- | --- |
| `.fbs` parser | Schema text | Recursive descent. Resolves names, expands a union into a type slot and a value slot, lays structs out. |
| `.bfbs` decoder | `flatc --binary --schema` | Reads the `reflection.Schema` table with the same wire reader. |

Both paths sort objects by name and fields by id, then the emitter prints
Mojo. `test_codegen` checks that the two strings are equal for the benchmark
schema and for `features.fbs`. `flatc --json` reads a buffer this library
built for `Holder`, including the inline `Point` and `Mixed` structs.

A negative vtable offset is normal. Shared vtables often sit at a higher
address than the tables that use them. The soffset is a signed 32-bit value.
Mojo's `Int(some_i32_call())` can zero-extend that value when the call is
written as one expression. The reader binds the `Int32` to a name first, then
sign-extends it. Without that, a shared vtable looks out of range.

## Views and copies

A view holds a `Span` and the table position. A scalar accessor adds the
vtable offset and loads the little-endian value. It does not allocate.

`unpack` walks the same accessors and builds `String` and `List` values. That
copy is the honest cost of keeping the data after the buffer is dropped. The
Zig benchmark does the same split: `decodeRoot`, then a domain copy.

The verifier checks the root offset, the vtable size, and that each present
field offset lands inside the object. Generated `verify_` functions also check
string terminators and vector lengths, and they recurse into nested tables up
to a depth of 64.

## FlexBuffers widths

The FlexBuffers builder writes forward. Each integer uses the narrowest width
that can hold it. `7` is one byte. `300` is two. A float that survives a
round trip through `float32` is stored as `float32`. Maps sort keys and share
key bytes inside one buffer.

The reader understands the widths, typed vectors, fixed vectors of length 2,
3, and 4, blobs, and nested maps. `test_read_gold` loads the official
`gold_flexbuffer_example.bin` and checks the map the Python reader returns:
`bar`, `foo`, `bool`, `mymap`, and `vec`.

## Ideas that were not used

| Idea | Why it is not the default |
| --- | --- |
| Build forward, then patch offsets | Every parent offset would be rewritten. The backward builder makes offsets positive as it goes. |
| Hash vtables | The linear scan is enough for a handful of shapes, and it does not allocate. |
| Share strings by default | Repeated strings are the exception in the v2 records. The switch exists for buffers that do repeat them. |
| SIMD string copies | Suite strings are short. The copy is already a tight byte loop into the builder block. |
| A reflective packer | Walking a field table at runtime is what the generated code avoids. |
| A FlexBuffers view type | Every access would still branch on the type byte. The owned tree matches how the tests check values. |

## The conda package pins one compiler

`.mojoc` files match the compiler that wrote them. Build, host, and run all
require `mojo-compiler` 1.0.0. The default `pin_compatible` range is
`>=1.0.0,<2.0a0`. That range lets a solver install 1.1.0, and 1.1.0 refuses
to load 1.0.0 bytecode. The run requirement therefore uses an upper bound of
`x.x.x`, which keeps the package on 1.0.0.
