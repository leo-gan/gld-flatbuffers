from std.testing import TestSuite, assert_equal, assert_true

from schema.bfbs import parse_bfbs_file
from schema.fbs import parse_fbs_file
from schema.model import BT_BYTE, BT_DOUBLE, BT_INT, BT_OBJ, BT_STRING, BT_UNION, BT_UTYPE, BT_VECTOR, Schema


def test_benchmark_shape() raises:
    var schema = parse_fbs_file("testdata/schema/benchmark_v2.fbs")
    assert_equal(len(schema.objects), 14)
    assert_equal(len(schema.enums), 1)
    assert_equal(schema.objects[schema.root].name, "benchmark.v2.FixtureRoot")
    assert_equal(schema.enums[0].name, "benchmark.v2.FixtureKind")
    assert_equal(schema.enums[0].underlying, BT_BYTE)
    assert_equal(len(schema.enums[0].values), 10)
    var message = schema.find_object("benchmark.v2.Message")
    assert_equal(len(schema.objects[message].fields), 8)
    assert_equal(schema.objects[message].fields[4].name, "f_string")
    assert_equal(schema.objects[message].fields[4].ty.base, BT_STRING)
    assert_true(schema.objects[message].fields[4].optional)
    var telemetry = schema.find_object("benchmark.v2.Telemetry")
    assert_equal(schema.objects[telemetry].fields[3].name, "values")
    assert_equal(schema.objects[telemetry].fields[3].ty.base, BT_VECTOR)
    assert_equal(schema.objects[telemetry].fields[3].ty.element, BT_DOUBLE)
    var document = schema.find_object("benchmark.v2.Document")
    assert_equal(schema.objects[document].fields[2].name, "meta")
    assert_equal(schema.objects[document].fields[2].ty.base, BT_OBJ)
    var meta_index = schema.objects[document].fields[2].ty.index
    assert_equal(schema.objects[meta_index].name, "benchmark.v2.DocumentMeta")


def test_features_shape() raises:
    var schema = parse_fbs_file("testdata/schema/features.fbs")
    assert_equal(schema.file_ident, "HOLD")
    assert_equal(schema.file_ext, "bin")
    var holder = schema.find_object("features.Holder")
    assert_equal(schema.root, holder)
    assert_equal(schema.objects[holder].fields[1].name, "color")
    assert_equal(schema.objects[holder].fields[1].default_int, Int64(2))
    assert_equal(schema.objects[holder].fields[1].ty.base, BT_BYTE)
    var point = schema.find_object("features.Point")
    assert_true(schema.objects[point].is_struct)
    assert_equal(schema.objects[point].bytesize, 8)
    assert_equal(schema.objects[point].minalign, 4)
    var mixed = schema.find_object("features.Mixed")
    assert_equal(schema.objects[mixed].bytesize, 8)
    assert_equal(schema.objects[mixed].fields[0].padding, 1)
    assert_equal(schema.objects[mixed].fields[1].offset, 2)
    assert_equal(schema.objects[mixed].fields[2].offset, 4)
    assert_equal(schema.objects[holder].fields[4].name, "item_type")
    assert_equal(schema.objects[holder].fields[4].ty.base, BT_UTYPE)
    assert_equal(schema.objects[holder].fields[5].name, "item")
    assert_equal(schema.objects[holder].fields[5].ty.base, BT_UNION)
    assert_equal(schema.objects[holder].fields[6].name, "maybe")
    assert_true(schema.objects[holder].fields[6].optional)
    assert_equal(schema.objects[holder].fields[6].ty.base, BT_INT)
    assert_equal(schema.objects[holder].fields[8].ty.base, BT_VECTOR)
    assert_equal(schema.objects[holder].fields[7].name, "flags")
    assert_equal(schema.objects[holder].fields[7].default_int, Int64(0))
    assert_true(not schema.objects[holder].fields[7].optional)


def _same(a: Schema, b: Schema) raises:
    assert_equal(len(a.objects), len(b.objects))
    assert_equal(len(a.enums), len(b.enums))
    assert_equal(a.file_ident, b.file_ident)
    assert_equal(a.file_ext, b.file_ext)
    assert_equal(a.objects[a.root].name, b.objects[b.root].name)
    for i in range(len(a.objects)):
        assert_equal(a.objects[i].name, b.objects[i].name)
        assert_equal(a.objects[i].is_struct, b.objects[i].is_struct)
        if a.objects[i].is_struct:
            assert_equal(a.objects[i].bytesize, b.objects[i].bytesize)
            assert_equal(a.objects[i].minalign, b.objects[i].minalign)
        assert_equal(len(a.objects[i].fields), len(b.objects[i].fields))
        for f in range(len(a.objects[i].fields)):
            assert_equal(a.objects[i].fields[f].name, b.objects[i].fields[f].name)
            assert_equal(a.objects[i].fields[f].id, b.objects[i].fields[f].id)
            assert_equal(a.objects[i].fields[f].ty.base, b.objects[i].fields[f].ty.base)
            assert_equal(a.objects[i].fields[f].ty.element, b.objects[i].fields[f].ty.element)
            assert_equal(a.objects[i].fields[f].ty.index, b.objects[i].fields[f].ty.index)
            assert_equal(a.objects[i].fields[f].optional, b.objects[i].fields[f].optional)
            assert_equal(a.objects[i].fields[f].default_int, b.objects[i].fields[f].default_int)
            if a.objects[i].is_struct:
                assert_equal(a.objects[i].fields[f].offset, b.objects[i].fields[f].offset)
                assert_equal(a.objects[i].fields[f].padding, b.objects[i].fields[f].padding)
    for i in range(len(a.enums)):
        assert_equal(a.enums[i].name, b.enums[i].name)
        assert_equal(a.enums[i].is_union, b.enums[i].is_union)
        assert_equal(a.enums[i].underlying, b.enums[i].underlying)
        assert_equal(len(a.enums[i].values), len(b.enums[i].values))
        for v in range(len(a.enums[i].values)):
            assert_equal(a.enums[i].values[v].name, b.enums[i].values[v].name)
            assert_equal(a.enums[i].values[v].value, b.enums[i].values[v].value)
            assert_equal(a.enums[i].values[v].union_object, b.enums[i].values[v].union_object)


def test_fbs_matches_bfbs() raises:
    var left = parse_fbs_file("testdata/schema/benchmark_v2.fbs")
    var right = parse_bfbs_file("testdata/schema/benchmark_v2.bfbs")
    _same(left, right)
    left = parse_fbs_file("testdata/schema/features.fbs")
    right = parse_bfbs_file("testdata/schema/features.bfbs")
    _same(left, right)


def test_include() raises:
    var schema = parse_fbs_file("testdata/schema/parent.fbs")
    assert_true(schema.find_object("demo.child.Kid") >= 0)
    var parent = schema.find_object("demo.parent.Parent")
    assert_equal(schema.objects[parent].fields[0].ty.base, BT_OBJ)
    assert_equal(schema.objects[schema.objects[parent].fields[0].ty.index].name, "demo.child.Kid")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
