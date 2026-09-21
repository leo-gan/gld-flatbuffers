from std.collections import Dict, List, Span


struct Builder:
    """Builds one FlatBuffers buffer from the high addresses downward.

    The cursor starts at the end of a zeroed block. Each value is stored
    before the values that point at it, so a `uoffset` is always a positive
    distance. `clear` keeps the block so the next message does not allocate.
    """

    var buf: List[Byte]
    var head: Int
    var minalign: Int
    var nested: Bool
    var object_end: Int
    var vtable: List[Int]
    var vt_offsets: List[Int]
    var vector_elems: Int
    var force_defaults: Bool
    var finished: Bool
    var shared: Dict[String, Int]
    var share_strings: Bool

    def __init__(out self, capacity: Int = 256):
        var cap = capacity
        if cap < 1:
            cap = 1
        self.buf = List[Byte](capacity=cap)
        for _ in range(cap):
            self.buf.append(Byte(0))
        self.head = cap
        self.minalign = 1
        self.nested = False
        self.object_end = 0
        self.vtable = List[Int]()
        self.vt_offsets = List[Int]()
        self.vector_elems = 0
        self.force_defaults = False
        self.finished = False
        self.shared = Dict[String, Int]()
        self.share_strings = False

    def clear(mut self):
        """Drop the previous message and keep the allocated block."""
        self.head = len(self.buf)
        self.minalign = 1
        self.nested = False
        self.object_end = 0
        self.vtable = List[Int]()
        self.vt_offsets = List[Int]()
        self.vector_elems = 0
        self.force_defaults = False
        self.finished = False
        self.shared = Dict[String, Int]()

    def offset(self) -> Int:
        return len(self.buf) - self.head

    def finished_list(self) raises -> List[Byte]:
        if not self.finished:
            raise Error("builder is not finished")
        var out = List[Byte](capacity=len(self.buf) - self.head)
        for i in range(self.head, len(self.buf)):
            out.append(self.buf[i])
        return out^

    def set_force_defaults(mut self, enabled: Bool):
        self.force_defaults = enabled

    def set_share_strings(mut self, enabled: Bool):
        self.share_strings = enabled

    def grow(mut self) raises:
        var old_len = len(self.buf)
        var new_len = old_len * 2
        if new_len < 1:
            new_len = 1
        if new_len > 2147483647:
            raise Error("flatbuffers: buffer exceeds 2GiB")
        var fresh = List[Byte](capacity=new_len)
        var prefix = new_len - old_len
        for _ in range(prefix):
            fresh.append(Byte(0))
        for i in range(old_len):
            fresh.append(self.buf[i])
        self.head += prefix
        self.buf = fresh^

    def prep(mut self, size: Int, additional: Int) raises:
        if size > self.minalign:
            self.minalign = size
        var align_size = (-(len(self.buf) - self.head + additional)) & (size - 1)
        while self.head < align_size + size + additional:
            self.grow()
        self.pad(align_size)

    def pad(mut self, n: Int):
        for _ in range(n):
            self.place_u8(0)

    def place_u8(mut self, v: UInt8):
        self.head -= 1
        self.buf[self.head] = Byte(v)

    def place_u16(mut self, v: UInt16):
        self.head -= 2
        self.buf[self.head] = Byte(UInt8(v & 0xFF))
        self.buf[self.head + 1] = Byte(UInt8((v >> UInt16(8)) & 0xFF))

    def place_u32(mut self, v: UInt32):
        self.head -= 4
        self.buf[self.head] = Byte(UInt8(v & 0xFF))
        self.buf[self.head + 1] = Byte(UInt8((v >> UInt32(8)) & 0xFF))
        self.buf[self.head + 2] = Byte(UInt8((v >> UInt32(16)) & 0xFF))
        self.buf[self.head + 3] = Byte(UInt8((v >> UInt32(24)) & 0xFF))

    def place_u64(mut self, v: UInt64):
        self.head -= 8
        for i in range(8):
            var shift = UInt64(i) * 8
            self.buf[self.head + i] = Byte(UInt8((v >> shift) & 0xFF))

    def place_i8(mut self, v: Int8):
        self.place_u8(UInt8(v))

    def place_i16(mut self, v: Int16):
        self.place_u16(UInt16(v))

    def place_i32(mut self, v: Int32):
        self.place_u32(UInt32(v))

    def place_i64(mut self, v: Int64):
        self.place_u64(UInt64(v))

    def place_f32(mut self, v: Float32):
        self.place_u32(UInt32(v.to_bits()))

    def place_f64(mut self, v: Float64):
        self.place_u64(UInt64(v.to_bits()))

    def write_i32_at(mut self, index: Int, v: Int32):
        var bits = UInt32(v)
        self.buf[index] = Byte(UInt8(bits & 0xFF))
        self.buf[index + 1] = Byte(UInt8((bits >> UInt32(8)) & 0xFF))
        self.buf[index + 2] = Byte(UInt8((bits >> UInt32(16)) & 0xFF))
        self.buf[index + 3] = Byte(UInt8((bits >> UInt32(24)) & 0xFF))

    def u16_at(self, index: Int) -> UInt16:
        return UInt16(self.buf[index]) | (UInt16(self.buf[index + 1]) << UInt16(8))

    def prepend_u8(mut self, v: UInt8) raises:
        self.prep(1, 0)
        self.place_u8(v)

    def prepend_u16(mut self, v: UInt16) raises:
        self.prep(2, 0)
        self.place_u16(v)

    def prepend_u32(mut self, v: UInt32) raises:
        self.prep(4, 0)
        self.place_u32(v)

    def prepend_u64(mut self, v: UInt64) raises:
        self.prep(8, 0)
        self.place_u64(v)

    def prepend_i8(mut self, v: Int8) raises:
        self.prep(1, 0)
        self.place_i8(v)

    def prepend_i16(mut self, v: Int16) raises:
        self.prep(2, 0)
        self.place_i16(v)

    def prepend_i32(mut self, v: Int32) raises:
        self.prep(4, 0)
        self.place_i32(v)

    def prepend_i64(mut self, v: Int64) raises:
        self.prep(8, 0)
        self.place_i64(v)

    def prepend_f32(mut self, v: Float32) raises:
        self.prep(4, 0)
        self.place_f32(v)

    def prepend_f64(mut self, v: Float64) raises:
        self.prep(8, 0)
        self.place_f64(v)

    def prepend_bool(mut self, v: Bool) raises:
        var b: UInt8 = 0
        if v:
            b = 1
        self.prepend_u8(b)

    def prepend_uoffset_relative(mut self, off: Int) raises:
        self.prep(4, 0)
        if off > self.offset():
            raise Error("offset arithmetic")
        var off2 = self.offset() - off + 4
        self.place_u32(UInt32(off2))

    def prepend_soffset_relative(mut self, off: Int) raises:
        self.prep(4, 0)
        if off > self.offset():
            raise Error("offset arithmetic")
        var off2 = self.offset() - off + 4
        self.place_i32(Int32(off2))

    def assert_nested(self) raises:
        if not self.nested:
            raise Error("not nested")

    def assert_not_nested(self) raises:
        if self.nested:
            raise Error("nested")

    def slot(mut self, slotnum: Int) raises:
        self.assert_nested()
        self.vtable[slotnum] = self.offset()

    def start_object(mut self, numfields: Int) raises:
        self.assert_not_nested()
        self.vtable = List[Int]()
        for _ in range(numfields):
            self.vtable.append(0)
        self.object_end = self.offset()
        self.nested = True

    def end_object(mut self) raises -> Int:
        self.assert_nested()
        self.nested = False
        return self.write_vtable()

    def _vtable_matches(self, stored_off: Int, expect: List[Int]) -> Bool:
        var pos = len(self.buf) - stored_off
        if pos < 0 or pos + 4 > len(self.buf):
            return False
        var vbytes = Int(self.u16_at(pos))
        var nfields = vbytes // 2 - 2
        if nfields != len(expect):
            return False
        for i in range(nfields):
            var at = pos + 4 + 2 * i
            if at + 2 > len(self.buf):
                return False
            if Int(self.u16_at(at)) != expect[i]:
                return False
        return True

    def write_vtable(mut self) raises -> Int:
        self.prepend_soffset_relative(0)
        var object_offset = self.offset()
        var key = List[Int]()
        var trim = True
        var i = len(self.vtable) - 1
        while i >= 0:
            var elem = self.vtable[i]
            i -= 1
            if elem == 0:
                if trim:
                    continue
                key.append(0)
            else:
                key.append(object_offset - elem)
                trim = False
        var expect = List[Int]()
        var k = len(key) - 1
        while k >= 0:
            expect.append(key[k])
            k -= 1

        var found = -1
        for vi in range(len(self.vt_offsets)):
            if self._vtable_matches(self.vt_offsets[vi], expect):
                found = self.vt_offsets[vi]
                break

        if found < 0:
            trim = True
            var trailing = 0
            i = len(self.vtable) - 1
            while i >= 0:
                var off = 0
                var elem = self.vtable[i]
                i -= 1
                if elem == 0:
                    if trim:
                        trailing += 1
                        continue
                else:
                    off = object_offset - elem
                    trim = False
                self.place_u16(UInt16(off))
            var object_size = object_offset - self.object_end
            self.place_u16(UInt16(object_size))
            var v_bytes = (len(self.vtable) - trailing + 2) * 2
            self.place_u16(UInt16(v_bytes))
            var object_start = len(self.buf) - object_offset
            var soff = self.offset() - object_offset
            self.write_i32_at(object_start, Int32(soff))
            found = self.offset()
            self.vt_offsets.append(found)
        else:
            var object_start = len(self.buf) - object_offset
            self.head = object_start
            var soff = found - object_offset
            self.write_i32_at(self.head, Int32(soff))

        self.vtable = List[Int]()
        return object_offset

    def add_bool(mut self, slotnum: Int, value: Bool, default: Bool) raises:
        if value != default or self.force_defaults:
            self.prepend_bool(value)
            self.slot(slotnum)

    def add_i8(mut self, slotnum: Int, value: Int8, default: Int8) raises:
        if value != default or self.force_defaults:
            self.prepend_i8(value)
            self.slot(slotnum)

    def add_u8(mut self, slotnum: Int, value: UInt8, default: UInt8) raises:
        if value != default or self.force_defaults:
            self.prepend_u8(value)
            self.slot(slotnum)

    def add_i16(mut self, slotnum: Int, value: Int16, default: Int16) raises:
        if value != default or self.force_defaults:
            self.prepend_i16(value)
            self.slot(slotnum)

    def add_u16(mut self, slotnum: Int, value: UInt16, default: UInt16) raises:
        if value != default or self.force_defaults:
            self.prepend_u16(value)
            self.slot(slotnum)

    def add_i32(mut self, slotnum: Int, value: Int32, default: Int32) raises:
        if value != default or self.force_defaults:
            self.prepend_i32(value)
            self.slot(slotnum)

    def add_u32(mut self, slotnum: Int, value: UInt32, default: UInt32) raises:
        if value != default or self.force_defaults:
            self.prepend_u32(value)
            self.slot(slotnum)

    def add_i64(mut self, slotnum: Int, value: Int64, default: Int64) raises:
        if value != default or self.force_defaults:
            self.prepend_i64(value)
            self.slot(slotnum)

    def add_u64(mut self, slotnum: Int, value: UInt64, default: UInt64) raises:
        if value != default or self.force_defaults:
            self.prepend_u64(value)
            self.slot(slotnum)

    def add_f32(mut self, slotnum: Int, value: Float32, default: Float32) raises:
        if value != default or self.force_defaults:
            self.prepend_f32(value)
            self.slot(slotnum)

    def add_f64(mut self, slotnum: Int, value: Float64, default: Float64) raises:
        if value != default or self.force_defaults:
            self.prepend_f64(value)
            self.slot(slotnum)

    def add_offset(mut self, slotnum: Int, off: Int) raises:
        if off != 0 or self.force_defaults:
            self.prepend_uoffset_relative(off)
            self.slot(slotnum)

    def add_struct(mut self, slotnum: Int, off: Int) raises:
        if off != 0:
            if off != self.offset():
                raise Error("struct is not inline")
            self.slot(slotnum)

    def start_vector(mut self, elem_size: Int, num_elems: Int, alignment: Int) raises -> Int:
        self.assert_not_nested()
        self.nested = True
        self.vector_elems = num_elems
        self.prep(4, elem_size * num_elems)
        self.prep(alignment, elem_size * num_elems)
        return self.offset()

    def end_vector(mut self) raises -> Int:
        self.assert_nested()
        self.nested = False
        self.place_u32(UInt32(self.vector_elems))
        self.vector_elems = 0
        return self.offset()

    def create_string(mut self, text: String) raises -> Int:
        if self.share_strings and text in self.shared:
            return self.shared[text]
        var off = self.create_string_bytes(text.as_bytes())
        if self.share_strings:
            self.shared[text] = off
        return off

    def create_string_bytes[origin: ImmOrigin](mut self, raw: Span[Byte, origin]) raises -> Int:
        self.assert_not_nested()
        self.nested = True
        var n = len(raw)
        self.prep(4, n + 1)
        self.place_u8(0)
        self.head -= n
        for i in range(n):
            self.buf[self.head + i] = raw[i]
        self.vector_elems = n
        return self.end_vector()

    def create_byte_vector[origin: ImmOrigin](mut self, raw: Span[Byte, origin]) raises -> Int:
        self.assert_not_nested()
        self.nested = True
        var n = len(raw)
        self.prep(4, n)
        self.head -= n
        for i in range(n):
            self.buf[self.head + i] = raw[i]
        self.vector_elems = n
        return self.end_vector()

    def create_offset_vector(mut self, offsets: List[Int]) raises -> Int:
        var n = len(offsets)
        _ = self.start_vector(4, n, 4)
        var i = n - 1
        while i >= 0:
            self.prepend_uoffset_relative(offsets[i])
            i -= 1
        return self.end_vector()

    def finish(mut self, root: Int, file_id: String = "") raises:
        self.finish_with(root, False, file_id)

    def finish_size_prefixed(mut self, root: Int, file_id: String = "") raises:
        self.finish_with(root, True, file_id)

    def finish_with(mut self, root: Int, size_prefix: Bool, file_id: String) raises:
        if self.nested:
            raise Error("nested")
        var prep_size = 4
        var has_id = file_id.byte_length() != 0
        if has_id:
            if file_id.byte_length() != 4:
                raise Error("file identifier must be 4 bytes")
            prep_size += 4
        if size_prefix:
            prep_size += 4
        self.prep(self.minalign, prep_size)
        if has_id:
            self.prep(4, 4)
            var raw = file_id.as_bytes()
            self.place_u8(UInt8(raw[3]))
            self.place_u8(UInt8(raw[2]))
            self.place_u8(UInt8(raw[1]))
            self.place_u8(UInt8(raw[0]))
        self.prepend_uoffset_relative(root)
        if size_prefix:
            var size = len(self.buf) - self.head
            self.prepend_i32(Int32(size))
        self.finished = True
