# Examples

These snippets match the generated types in `tests/generated`. Build them with
`mojo run -I src -I tests/generated`.

## Owned round trip

`encode_Message` builds a buffer whose root is a `Message`. `decode_Message`
copies the fields out.

```mojo
from benchmark_v2 import Message, decode_Message, encode_Message

var msg = Message()
msg.f_bool = True
msg.f_int32 = 150
msg.f_string = "hi"
var buf = encode_Message(msg)
var back = decode_Message(buf)
```

Fields that still hold their schema default are left out of the buffer. `f_bool_2`
stays false and is not stored. Read it back and you get false again.

## A view over the same bytes

```mojo
from benchmark_v2 import view_Message

var view = view_Message(buf)
var n = view.f_int32()
var text = view.f_string()
```

`f_int32` reads four bytes at the vtable offset. `f_string` copies the UTF-8
bytes out because a Mojo `String` owns its storage. The integer read does not
allocate.

## Nested tables and vectors

```mojo
from benchmark_v2 import Document, DocumentItem, encode_Document

var doc = Document()
doc.id = "d1"
doc.has_meta = True
doc.meta.region = "us"
var item = DocumentItem()
item.sku = "ab"
item.qty = 4
doc.items.append(item^)
var bytes = encode_Document(doc)
```

`has_meta` is the presence bit. Leave it false and the meta table is absent.
An empty `items` list is also absent. A list of length one is a vector of
table offsets.

## Structs, unions, and optional scalars

```mojo
from std.collections import Optional
from features import Holder, Item_Text, encode_Holder

var h = Holder()
h.has_point = True
h.point.x = 1.5
h.point.y = -2.0
h.item_type = Item_Text
h.item_Text.value = "hello"
h.maybe = Optional(Int32(0))
```

`Point` is inline. Its eight bytes sit inside `Holder`, not behind an offset.
`maybe` is optional, so zero is stored. A missing `maybe` would be `None`,
which is a different value from zero.

`item_type` selects which table was packed. `Item_Text` is the generated name
of that union member.

## FlexBuffers

```mojo
from flex.builder import FlexBuilder
from flex.reader import flex_loads

var b = FlexBuilder()
var start = b.start_vector()
b.int(1)
b.int(2)
b.int(3)
b.end_vector(start)
var tree = flex_loads(b.finish())
```

`tree.kind()` is the root type. For a map, `tree.find(tree.root, "harbor")`
returns the child index. The official gold buffer in the test suite is read
the same way.
