from std.collections import Optional
from std.testing import TestSuite, assert_equal, assert_true

from benchmark_v2 import (
    Document,
    DocumentItem,
    Message,
    Telemetry,
    decode_Document,
    decode_Message,
    decode_Telemetry,
    encode_Document,
    encode_Message,
    encode_Telemetry,
    verify_Message,
    view_Message,
)
from features import Item_Count, Item_Text, decode_Holder, encode_Holder, Holder
from wire.reader import root_pos


def test_message_view_and_copy() raises:
    var msg = Message()
    msg.f_bool = True
    msg.f_int32 = 150
    msg.f_int64 = 9
    msg.f_float64 = 1.5
    msg.f_string = "hi"
    var buf = encode_Message(msg)
    var back = decode_Message(buf)
    assert_true(back.f_bool)
    assert_equal(back.f_int32, Int32(150))
    assert_equal(back.f_int64, Int64(9))
    assert_true(back.f_float64 == 1.5)
    assert_equal(back.f_string, "hi")
    assert_true(not back.f_bool_2)
    assert_equal(back.f_string_2, "")
    var view = view_Message(buf)
    assert_equal(view.f_int32(), Int32(150))
    assert_equal(view.f_string(), "hi")
    verify_Message(buf, root_pos(buf, False), 0)


def test_document_children() raises:
    var doc = Document()
    doc.id = "d1"
    doc.status = 2
    doc.has_meta = True
    doc.meta.region = "us"
    doc.meta.version = 3
    var item = DocumentItem()
    item.sku = "ab"
    item.qty = 4
    item.price_minor = 99
    doc.items.append(item^)
    var back = decode_Document(encode_Document(doc))
    assert_equal(back.id, "d1")
    assert_equal(back.status, Int32(2))
    assert_true(back.has_meta)
    assert_equal(back.meta.region, "us")
    assert_equal(back.meta.version, Int32(3))
    assert_equal(len(back.items), 1)
    assert_equal(back.items[0].sku, "ab")
    assert_equal(back.items[0].qty, Int32(4))
    assert_equal(back.items[0].price_minor, Int64(99))


def test_telemetry_vectors() raises:
    var tel = Telemetry()
    tel.source = "s"
    tel.ts = 10
    tel.tags.append("a")
    tel.tags.append("b")
    tel.values.append(1.5)
    tel.values.append(2.0)
    var back = decode_Telemetry(encode_Telemetry(tel))
    assert_equal(back.source, "s")
    assert_equal(back.ts, Int64(10))
    assert_equal(len(back.tags), 2)
    assert_equal(back.tags[1], "b")
    assert_equal(len(back.values), 2)
    assert_true(back.values[0] == 1.5)


def test_holder_features() raises:
    var h = Holder()
    h.name = "kelp"
    h.color.value = 2
    h.has_point = True
    h.point.x = 1.5
    h.point.y = -2.0
    h.has_mixed = True
    h.mixed.a = 1
    h.mixed.b = 2
    h.mixed.c = 3
    h.item_type = Item_Text
    h.item_Text.value = "hello"
    h.maybe = Optional(Int32(0))
    h.flags = 9
    h.scores.append(Float32(4.0))
    h.tags.append("z")
    var back = decode_Holder(encode_Holder(h))
    assert_equal(back.name, "kelp")
    assert_equal(back.color.value, Int8(2))
    assert_true(back.has_point)
    assert_true(back.point.x == 1.5)
    assert_true(back.point.y == -2.0)
    assert_equal(back.mixed.a, UInt8(1))
    assert_equal(back.mixed.c, Int32(3))
    assert_equal(back.item_type, Item_Text)
    assert_equal(back.item_Text.value, "hello")
    assert_true(Bool(back.maybe))
    assert_equal(back.maybe.value(), Int32(0))
    assert_equal(back.flags, UInt32(9))
    assert_equal(len(back.scores), 1)
    assert_equal(back.tags[0], "z")

    var other = Holder()
    other.item_type = Item_Count
    other.item_Count.n = 4
    var again = decode_Holder(encode_Holder(other))
    assert_equal(again.item_type, Item_Count)
    assert_equal(again.item_Count.n, Int32(4))
    assert_equal(again.name, "")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
