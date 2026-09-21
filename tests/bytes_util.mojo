from std.collections import List, Span


def bytes_of(*values: Int) -> List[Byte]:
    var out = List[Byte]()
    for i in range(len(values)):
        out.append(Byte(values[i] & 0xFF))
    return out^


def hex_of[origin: ImmOrigin](data: Span[Byte, origin]) -> String:
    var s = String()
    var digits = String("0123456789abcdef")
    for i in range(len(data)):
        if i != 0:
            s += " "
        var b = Int(data[i])
        s += digits[byte=b >> 4]
        s += digits[byte=b & 15]
    return s


def parse_hex(text: String) -> List[Byte]:
    var out = List[Byte]()
    var i = 0
    var raw = text.as_bytes()
    while i + 1 < len(raw):
        var hi = _hex_val(raw[i])
        var lo = _hex_val(raw[i + 1])
        out.append(Byte(hi * 16 + lo))
        i += 2
    return out^


def _hex_val(b: Byte) -> Int:
    var c = Int(b)
    if c >= ord("0") and c <= ord("9"):
        return c - ord("0")
    if c >= ord("a") and c <= ord("f"):
        return c - ord("a") + 10
    if c >= ord("A") and c <= ord("F"):
        return c - ord("A") + 10
    return 0


def assert_hex[origin: ImmOrigin](data: Span[Byte, origin], text: String) raises:
    var want = parse_hex(text)
    if len(data) != len(want):
        raise Error("len " + String(len(data)) + " != " + String(len(want)) + " got " + hex_of(data))
    for i in range(len(want)):
        if data[i] != want[i]:
            raise Error("mismatch at " + String(i) + " got " + hex_of(data))
