from std.collections import List
from std.testing import TestSuite, assert_equal, assert_true

from bytes_util import assert_hex, parse_hex
from flex.builder import FlexBuilder
from flex.kind import F_BLOB, F_BOOL, F_FLOAT, F_INT, F_MAP, F_NULL, F_STRING, F_VECTOR
from flex.reader import flex_loads


def _vec3() raises -> List[Byte]:
    var b = FlexBuilder()
    var start = b.start_vector()
    b.int(1)
    b.int(2)
    b.int(3)
    b.end_vector(start)
    return b.finish()


def test_scalars() raises:
    var b = FlexBuilder()
    b.int(7)
    assert_hex(b.finish(), "070401")
    b = FlexBuilder()
    b.int(0)
    assert_hex(b.finish(), "000401")
    b = FlexBuilder()
    b.int(-1)
    assert_hex(b.finish(), "ff0401")
    b = FlexBuilder()
    b.int(300)
    assert_hex(b.finish(), "2c010502")
    b = FlexBuilder()
    b.bool(True)
    assert_hex(b.finish(), "016801")
    b = FlexBuilder()
    b.bool(False)
    assert_hex(b.finish(), "006801")
    b = FlexBuilder()
    b.float(1.5)
    assert_hex(b.finish(), "0000c03f0e04")
    b = FlexBuilder()
    b.null()
    assert_hex(b.finish(), "000001")


def test_string_and_blob() raises:
    var b = FlexBuilder()
    b.string("kelp")
    assert_hex(b.finish(), "046b656c7000051401")
    b = FlexBuilder()
    b.string("")
    assert_hex(b.finish(), "0000011401")
    b = FlexBuilder()
    b.string("harbor")
    assert_hex(b.finish(), "06686172626f7200071401")
    var raw = List[Byte]()
    raw.append(Byte(0x6B))
    raw.append(Byte(0x65))
    raw.append(Byte(0x6C))
    raw.append(Byte(0x70))
    b = FlexBuilder()
    b.blob(raw)
    assert_hex(b.finish(), "046b656c70046401")


def test_vector_and_map() raises:
    var buf = _vec3()
    assert_hex(buf, "03010203040404062801")
    var b = FlexBuilder()
    var start = b.start_vector()
    b.end_vector(start)
    assert_hex(b.finish(), "00002801")
    b = FlexBuilder()
    start = b.start_map()
    b.key("harbor")
    b.string("kelp")
    b.end_map(start)
    assert_hex(b.finish(), "686172626f7200046b656c7000010e0101010a14022401")
    b = FlexBuilder()
    start = b.start_map()
    b.key("n")
    b.int(1)
    b.key("s")
    b.string("z")
    b.key("v")
    var inner = b.start_vector()
    b.int(1)
    b.int(2)
    b.int(3)
    b.end_vector(inner)
    b.end_map(start)
    assert_hex(b.finish(), "6e007300017a007600030102030404040311100c03010301130f041428062401")


def test_read_roundtrip() raises:
    var b = FlexBuilder()
    var start = b.start_map()
    b.key("harbor")
    b.string("kelp")
    b.end_map(start)
    var buf = b.finish()
    var tree = flex_loads(buf)
    assert_equal(tree.kind(), F_MAP)
    var child = tree.find(tree.root, "harbor")
    assert_true(child >= 0)
    assert_equal(tree.nodes[child].kind, F_STRING)
    assert_equal(tree.nodes[child].s, "kelp")

    var nums = parse_hex("070401")
    tree = flex_loads(nums)
    assert_equal(tree.kind(), F_INT)
    assert_equal(tree.nodes[tree.root].i, Int64(7))

    var neg = parse_hex("ff0401")
    tree = flex_loads(neg)
    assert_equal(tree.nodes[tree.root].i, Int64(-1))

    var wide = parse_hex("2c010502")
    tree = flex_loads(wide)
    assert_equal(tree.nodes[tree.root].i, Int64(300))

    var fl = parse_hex("0000c03f0e04")
    tree = flex_loads(fl)
    assert_equal(tree.kind(), F_FLOAT)
    assert_true(tree.nodes[tree.root].f == 1.5)

    var empty = parse_hex("000001")
    tree = flex_loads(empty)
    assert_equal(tree.kind(), F_NULL)


def test_read_gold() raises:
    var gold = parse_hex(
        "76656300044672656400000000008040014d069c0f0905000c0414226468226261720000030000000100000002000000030000006261723300000000010000000200000003000000626f6f6c73000401000100626f6f6c00666f6f006d796d617000010b0101016214074b3719251613700000000a00000001000000070000005800000048000000010000003d0000000000c8422d000000850000002e4e6a900e2428232601"
    )
    var tree = flex_loads(gold)
    assert_equal(tree.kind(), F_MAP)
    var bar = tree.find(tree.root, "bar")
    assert_equal(len(tree.nodes[bar].kids), 3)
    assert_equal(tree.nodes[tree.nodes[bar].kids[0]].i, Int64(1))
    assert_equal(tree.nodes[tree.nodes[bar].kids[2]].i, Int64(3))
    var foo = tree.find(tree.root, "foo")
    assert_equal(tree.nodes[foo].kind, F_FLOAT)
    assert_true(tree.nodes[foo].f == 100.0)
    var flag = tree.find(tree.root, "bool")
    assert_equal(tree.nodes[flag].kind, F_BOOL)
    assert_equal(tree.nodes[flag].u, UInt64(1))
    var nested = tree.find(tree.root, "mymap")
    var fred = tree.find(nested, "foo")
    assert_equal(tree.nodes[fred].s, "Fred")
    var vec = tree.find(tree.root, "vec")
    assert_equal(len(tree.nodes[vec].kids), 6)
    assert_equal(tree.nodes[tree.nodes[vec].kids[0]].i, Int64(-100))
    assert_equal(tree.nodes[tree.nodes[vec].kids[1]].s, "Fred")
    assert_equal(tree.nodes[tree.nodes[vec].kids[4]].kind, F_BOOL)


def test_reject_short() raises:
    for n in range(3):
        var buf = List[Byte]()
        for _ in range(n):
            buf.append(Byte(0))
        try:
            _ = flex_loads(buf)
            raise Error("expected failure")
        except e:
            assert_true(String(e).find("truncated") >= 0 or String(e).find("bad width") >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
