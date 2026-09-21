from std.collections import List
from std.testing import TestSuite, assert_true

from benchmark_v2 import Message, encode_Message, verify_Message
from bytes_util import parse_hex
from wire.reader import root_pos
from wire.verify import verify_file_identifier, verify_root


def _rejects(data: List[Byte]) -> Bool:
    try:
        verify_root(data, False)
    except e:
        var text = String(e)
        return text.find("truncated") >= 0 or text.find("bad") >= 0
    return False


def test_table_rejects() raises:
    assert_true(_rejects(List[Byte]()))
    assert_true(_rejects(parse_hex("0000")))
    assert_true(_rejects(parse_hex("000000")))


def test_file_identifier_rejects() raises:
    var short = parse_hex("04000000")
    var failed = False
    try:
        verify_file_identifier(short)
    except e:
        failed = String(e).find("truncated") >= 0
    assert_true(failed)
    failed = False
    try:
        verify_file_identifier(List[Byte]())
    except e:
        failed = String(e).find("truncated") >= 0
    assert_true(failed)


def test_valid_message_verifies() raises:
    var msg = Message()
    msg.f_int32 = 150
    msg.f_string = "hi"
    var buf = encode_Message(msg)
    verify_root(buf, False)
    verify_Message(buf, root_pos(buf, False), 0)
    var cut = List[Byte]()
    for i in range(4):
        cut.append(buf[i])
    assert_true(_rejects(cut))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
