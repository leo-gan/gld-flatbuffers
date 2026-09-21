# mojo-flatbuffers

mojo-flatbuffers is a [FlatBuffers](https://flatbuffers.dev/) serializer written
in [Mojo](https://www.modular.com/mojo). The runtime and the code generator are
Mojo. They do not wrap the C++ FlatBuffers library or flatcc.

<div class="grid cards" markdown="1">

-   __Why FlatBuffers__

    ---

    What a table, a vtable, a struct, and a FlexBuffers value are, and which
    parts of the format this library implements.

    [:octicons-arrow-right-24: Read Why FlatBuffers](why-flatbuffers.md)

-   __Instructions__

    ---

    Install Mojo 1.0.0 with pixi, write a `.fbs` schema, generate Mojo, run the
    tests, and publish this site.

    [:octicons-arrow-right-24: Open Instructions](instructions.md)

-   __Examples__

    ---

    Build a buffer, read it without copying, unpack it into Mojo values, and
    encode a FlexBuffers map.

    [:octicons-arrow-right-24: See Examples](examples.md)

-   __Techniques__

    ---

    How the builder, the vtable cache, and the two schema front ends work, and
    which ideas were kept or dropped.

    [:octicons-arrow-right-24: Read Techniques](techniques.md)

-   __Test data__

    ---

    What lives under `testdata/` (schemas, binary schemas, and the bytes the
    tests compare) and why each file is there.

    [:octicons-arrow-right-24: Read Test data](test-data.md)

</div>
