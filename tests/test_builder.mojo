from std.collections import List
from std.testing import TestSuite, assert_equal, assert_true

from bytes_util import assert_hex
from wire.builder import Builder
from wire.reader import (
    file_identifier,
    indirect_field,
    read_f64_field,
    read_i32_field,
    read_string_field,
    root_pos,
    vector_elem,
    vector_len,
)
from wire.scalar import read_f64, read_u32


def test_int_field() raises:
    var b = Builder(32)
    b.start_object(1)
    b.add_i32(0, 150, 0)
    var root = b.end_object()
    b.finish(root)
    var buf = b.finished_list()
    assert_hex(buf, "0c00000000000600080004000600000096000000")
    var pos = root_pos(buf, False)
    assert_equal(read_i32_field(buf, pos, 0, 0), Int32(150))
    assert_equal(read_i32_field(buf, pos, 1, Int32(9)), Int32(9))


def test_two_fields() raises:
    var b = Builder(64)
    b.start_object(2)
    b.add_i32(1, 7, 0)
    b.add_i32(0, 150, 0)
    var root = b.end_object()
    b.finish(root)
    var buf = b.finished_list()
    assert_hex(buf, "0c00000008000c0004000800080000009600000007000000")
    var pos = root_pos(buf, False)
    assert_equal(read_i32_field(buf, pos, 0, 0), Int32(150))
    assert_equal(read_i32_field(buf, pos, 1, 0), Int32(7))


def test_string_field() raises:
    var b = Builder(64)
    var s = b.create_string("hi")
    b.start_object(1)
    b.add_offset(0, s)
    var root = b.end_object()
    b.finish(root)
    var buf = b.finished_list()
    assert_hex(buf, "0c000000000006000800040006000000040000000200000068690000")
    var pos = root_pos(buf, False)
    assert_equal(read_string_field(buf, pos, 0), "hi")
    assert_equal(read_string_field(buf, pos, 3), "")


def test_float_vector() raises:
    var b = Builder(128)
    _ = b.start_vector(8, 3, 8)
    b.prepend_f64(3.0)
    b.prepend_f64(2.0)
    b.prepend_f64(1.5)
    var vec = b.end_vector()
    b.start_object(1)
    b.add_offset(0, vec)
    var root = b.end_object()
    b.finish(root)
    var buf = b.finished_list()
    assert_hex(
        buf,
        "0c0000000000060008000400060000000400000003000000000000000000f83f00000000000000400000000000000840",
    )
    var pos = root_pos(buf, False)
    var vpos = indirect_field(buf, pos, 0)
    assert_equal(vector_len(buf, vpos), 3)
    assert_true(read_f64(buf, vector_elem(buf, vpos, 0, 8)) == 1.5)
    assert_true(read_f64(buf, vector_elem(buf, vpos, 1, 8)) == 2.0)
    assert_true(read_f64(buf, vector_elem(buf, vpos, 2, 8)) == 3.0)
    assert_true(read_f64_field(buf, pos, 1, 0.0) == 0.0)


def test_file_identifier_and_size() raises:
    var b = Builder(32)
    b.start_object(1)
    b.add_i32(0, 1, 0)
    var root = b.end_object()
    b.finish(root, "ABCD")
    var buf = b.finished_list()
    assert_hex(buf, "100000004142434400000600080004000600000001000000")
    assert_equal(file_identifier(buf), "ABCD")

    var c = Builder(32)
    c.start_object(1)
    c.add_i32(0, 1, 0)
    root = c.end_object()
    c.finish_size_prefixed(root)
    var sized = c.finished_list()
    assert_hex(sized, "140000000c00000000000600080004000600000001000000")
    assert_equal(Int(read_u32(sized, 0)), len(sized) - 4)
    var spos = root_pos(sized, True)
    assert_equal(read_i32_field(sized, spos, 0, 0), Int32(1))


def test_omit_default() raises:
    var b = Builder(32)
    b.start_object(2)
    b.add_i32(1, 0, 0)
    b.add_i32(0, 5, 0)
    var root = b.end_object()
    b.finish(root)
    var buf = b.finished_list()
    assert_hex(buf, "0c00000000000600080004000600000005000000")
    var pos = root_pos(buf, False)
    assert_equal(read_i32_field(buf, pos, 0, 0), Int32(5))
    assert_equal(read_i32_field(buf, pos, 1, Int32(4)), Int32(4))


def test_vtable_dedup() raises:
    var b = Builder(128)
    b.start_object(1)
    b.add_i32(0, 1, 0)
    var a = b.end_object()
    b.start_object(1)
    b.add_i32(0, 2, 0)
    var c = b.end_object()
    var offs = List[Int]()
    offs.append(a)
    offs.append(c)
    var vec = b.create_offset_vector(offs)
    b.start_object(1)
    b.add_offset(0, vec)
    var root = b.end_object()
    b.finish(root)
    var buf = b.finished_list()
    assert_hex(
        buf,
        "04000000e2ffffff04000000020000001800000004000000f6ffffff0200000000000600080004000600000001000000",
    )


def test_builder_reuse() raises:
    var b = Builder(64)
    b.start_object(1)
    b.add_i32(0, 150, 0)
    var root = b.end_object()
    b.finish(root)
    var first = b.finished_list()
    b.clear()
    b.start_object(1)
    b.add_i32(0, 150, 0)
    root = b.end_object()
    b.finish(root)
    var second = b.finished_list()
    assert_equal(len(first), len(second))
    for i in range(len(first)):
        assert_equal(Int(first[i]), Int(second[i]))


def test_reject_short_root() raises:
    var buf = List[Byte]()
    buf.append(Byte(0))
    buf.append(Byte(0))
    try:
        _ = root_pos(buf, False)
        raise Error("expected failure")
    except e:
        assert_true(String(e).find("truncated") >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
