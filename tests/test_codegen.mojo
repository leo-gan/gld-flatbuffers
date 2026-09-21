from std.testing import TestSuite, assert_equal

from codegen.emit import emit_module
from schema.bfbs import parse_bfbs_file
from schema.fbs import parse_fbs_file


def test_both_front_ends_emit_the_same_text() raises:
    var from_text = emit_module(parse_fbs_file("testdata/schema/benchmark_v2.fbs"))
    var from_binary = emit_module(parse_bfbs_file("testdata/schema/benchmark_v2.bfbs"))
    assert_equal(from_text, from_binary)
    from_text = emit_module(parse_fbs_file("testdata/schema/features.fbs"))
    from_binary = emit_module(parse_bfbs_file("testdata/schema/features.bfbs"))
    assert_equal(from_text, from_binary)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
